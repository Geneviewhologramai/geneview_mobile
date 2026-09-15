import os
import sys
import math
import wave
import time
import struct
import datetime
import threading
import subprocess
import requests
import winsound
from pathlib import Path
from html.parser import HTMLParser
from flask import Flask, request, jsonify, send_file, render_template_string
from flask_cors import CORS
from piper.voice import PiperVoice

BASE_DIR = Path(__file__).resolve().parent

VIDEO_FILE = BASE_DIR / "GENEVIEW PROMO JOHN HASULYO.mov.mp4"
REPLY_AUDIO = BASE_DIR / "current_reply.wav"
VOICE_PATH = BASE_DIR / "voices" / "hu_HU-anna-medium.onnx"

# ==========================================================
# 0. HANGMOTOR ELŐKÉSZÍTÉSE (PIPER NATIVE)
# ==========================================================
voice_engine = None
if VOICE_PATH.exists():
    try:
        voice_engine = PiperVoice.load(str(VOICE_PATH))
        print(f"[HANGMOTOR]: {VOICE_PATH.name} sikeresen betöltve a memóriába.")
    except Exception as e:
        print(f"[HANGMOTOR HIBA]: {e}")
else:
    print(f"[FIGYELEM]: Nem található a modellfájl: {VOICE_PATH}")

app = Flask(__name__)
CORS(app)

# ==========================================================
# 1. BELSŐ CHRONOS ÓRA (IDŐ ÉS DÁTUM)
# ==========================================================
class ChronosEngine:
    NAPOK = ["hétfő", "kedd", "szerda", "csütörtök", "péntek", "szombat", "vasárnap"]
    HONAPOK = [
        "január", "február", "március", "április", "május", "június",
        "július", "augusztus", "szeptember", "október", "november", "december"
    ]
    NEVNAPOK = {
        (9, 13): "Kornél", (9, 14): "Szeréna és Roxána", (9, 15): "Enikő és Melitta",
        (9, 16): "Edit", (9, 17): "Zsófia"
    }

    @classmethod
    def answer_time(cls, q_norm: str) -> str:
        now = datetime.datetime.now()
        nap = cls.NAPOK[now.weekday()]
        honap = cls.HONAPOK[now.month - 1]
        nevnap = cls.NEVNAPOK.get((now.month, now.day), "a mai névnaposok")

        if any(k in q_norm for k in ["hany ora", "mennyi az ido", "pontos ido"]):
            return f"A belső órám szerint a pontos idő {now.strftime('%H:%M')}."
        if any(k in q_norm for k in ["milyen nap", "hanyadika", "datum"]):
            return f"Ma {now.year}. {honap} {now.day}., {nap} van."
        if any(k in q_norm for k in ["nevnap", "ki unnepli"]):
            return f"A mai napon {nevnap} ünnepli a névnapját."
        if any(k in q_norm for k in ["milyen ev", "melyik ev"]):
            return f"Jelenleg {now.year}-t írunk."
        return f"Ma {now.year}. {honap} {now.day}., {nap} van, az idő pedig {now.strftime('%H:%M')}."

# ==========================================================
# 2. SZŰRT DUCKDUCKGO KERESŐ
# ==========================================================
class CleanSnippetParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_snippet = False
        self.texts = []

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        cls_name = attrs_dict.get("class", "")
        if "result__snippet" in cls_name:
            self.in_snippet = True

    def handle_endtag(self, tag):
        if self.in_snippet and tag in ["a", "td", "div", "span"]:
            self.in_snippet = False

    def handle_data(self, data):
        if self.in_snippet:
            cleaned = data.strip()
            if cleaned and len(cleaned) > 20:
                low = cleaned.lower()
                if not any(bad in low for bad in ["tetris", "play the official", "free online game"]):
                    self.texts.append(cleaned)

def search_duckduckgo_filtered(query: str, max_results: int = 3) -> str:
    print(f"\n[DUCKDUCKGO KERESÉS]: '{query}'")
    snippets = []
    try:
        url = "https://html.duckduckgo.com/html/"
        payload = {"q": query, "kl": "hu-hu"}
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        res = requests.post(url, data=payload, headers=headers, timeout=5)
        if res.status_code == 200:
            parser = CleanSnippetParser()
            parser.feed(res.text)
            snippets = parser.texts[:max_results]
    except Exception as e:
        print(f"[HTML Search hiba]: {e}")

    if not snippets:
        try:
            try:
                from ddgs import DDGS
            except ImportError:
                from duckduckgo_search import DDGS
            with DDGS() as ddgs:
                for r in ddgs.text(query, region='hu-hu', max_results=max_results):
                    body = r.get('body', '').strip()
                    if body and not any(bad in body.lower() for bad in ["tetris", "play the official"]):
                        snippets.append(body)
        except Exception:
            pass

    return "\n".join(snippets) if snippets else ""

# ==========================================================
# 3. KOGNITÍV DÖNTÉSHOZÓ (IDENTITÁS + CHRONOS + LLM)
# ==========================================================
def think_and_answer(query: str) -> str:
    q_raw = query.strip()
    accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ö': 'o', 'ő': 'o', 'ú': 'u', 'ü': 'u', 'ű': 'u'}
    q_norm = "".join(accents.get(c, c) for c in q_raw.lower())

    # 1. Identitás kezelése
    identity_triggers = [
        "ki vagy", "ki vagy te", "mi vagy te", "mi a neved", 
        "hogy hivnak", "mutatkozz be", "ki beszel", "kivel beszelek"
    ]
    if any(trigger in q_norm for trigger in identity_triggers):
        return "Geneview vagyok, az önálló, szuverén digitális intelligenciád és jelenléted."

    # 2. Idő és naptár
    time_keys = ["hany ora", "mennyi az ido", "pontos ido", "milyen nap", "hanyadika", "datum", "milyen ev", "nevnap"]
    if any(k in q_norm for k in time_keys):
        return ChronosEngine.answer_time(q_norm)

    # 3. Ismert kérdések direkt kezelése
    if any(t in q_norm for t in ["forma 1", "formula 1", "f1"]):
        if any(w in q_norm for w in ["bajnok", "vilagbajnok", "nyert"]):
            return "A Formula 1 regnáló világbajnoka a holland Max Verstappen, a Red Bull Racing versenyzője."

    # 4. Általános webkeresés
    web_data = search_duckduckgo_filtered(q_raw)
    now = datetime.datetime.now()
    chronos_status = f"{now.year}. {ChronosEngine.HONAPOK[now.month-1]} {now.day}."

    sys_prompt = (
        "Te Geneview vagy, intelligens magyar entitás. "
        f"Mai dátum: {chronos_status}. "
        "A kapott adatok alapján válaszolj pontosan a kérdésre magyarul, maximum 1-2 kerek mondatban!"
    )
    full_prompt = f"KÉRDÉS: {q_raw}\n\nTALÁLATOK:\n{web_data}\n\nVálaszod:"

    try:
        res = requests.post(
            "http://127.0.0.1:11434/api/generate",
            json={
                "model": "llama3",
                "system": sys_prompt,
                "prompt": full_prompt,
                "stream": False,
                "options": {"temperature": 0.2}
            },
            timeout=7
        )
        if res.status_code == 200:
            txt = res.json().get("response", "").strip()
            if txt:
                return txt
    except Exception:
        pass

    if web_data:
        first = web_data.splitlines()[0].strip()
        if first.endswith(",") or first.endswith(" és") or first.endswith(" a"):
            first = first.rsplit(" ", 1)[0] + "."
        return f"A legfrissebb információk szerint: {first}"

    return f"Feldolgoztam a kérdésedet ({q_raw}). Készen állok a következő feladatra."

# ==========================================================
# 4. ÉLŐ BESZÉDSZINTÉZIS (PIPER ÉS SAPI TARTALÉK)
# ==========================================================
def synthesize_voice(text: str, out_wav: Path):
    success = False
    if voice_engine:
        try:
            with wave.open(str(out_wav), "wb") as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(voice_engine.config.sample_rate)
                voice_engine.synthesize(text, wav_file)
            if out_wav.exists() and out_wav.stat().st_size > 1000:
                print(f"[SZINTÉZIS]: Piper sikeres ({out_wav.stat().st_size} byte).")
                success = True
        except Exception as e:
            print(f"[PIPER HIBA]: {e}")

    if not success:
        clean = text.replace('"', '').replace("'", "")
        ps = f'Add-Type -AssemblyName System.Speech; $s = New-Object System.Speech.Synthesis.SpeechSynthesizer; $s.SetOutputToWaveFile("{out_wav}"); $s.Speak("{clean}"); $s.Dispose();'
        subprocess.run(["powershell", "-Command", ps], stdout=subprocess.DEVNULL)
        print(f"[SZINTÉZIS]: SAPI fallback lefutott.")

# ==========================================================
# 5. SZÁJMOZGÁS-SZINKRON (VISÉMÁK)
# ==========================================================
def extract_visemes(wav_p: Path):
    res = []
    if not wav_p.exists():
        return res
    try:
        with wave.open(str(wav_p), 'rb') as wf:
            frames, rate = wf.getnframes(), wf.getframerate()
            step = int(rate * 0.04)
            for i in range(0, frames, step):
                chunk = wf.readframes(step)
                if not chunk:
                    break
                cnt = len(chunk) // 2
                s = struct.unpack(f"{cnt}h", chunk[:cnt*2])
                rms = math.sqrt(sum(x**2 for x in s) / (cnt or 1))
                op = min(1.0, max(0.0, (rms - 200) / 2400.0))
                res.append({"t": round(i / float(rate), 2), "val": round(op, 2)})
    except Exception:
        pass
    return res

# ==========================================================
# 6. WEBES ÉS MOBIL INTERFÉSZ
# ==========================================================
MAIN_UI = """<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GENEVIEW</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; background: #000; color: #fff; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: space-between; height: 100vh; padding: 12px; overflow: hidden; }
        #header { width: 100%; max-width: 420px; display: flex; justify-content: space-between; font-size: 13px; font-weight: bold; color: #FFD700; }
        #status-card { width: 100%; max-width: 420px; background: rgba(13,27,42,0.9); border: 1px solid #1B4965; border-radius: 12px; padding: 12px; text-align: center; font-size: 14px; min-height: 48px; line-height: 1.4; color: #E0F2FE; }
        #stage { position: relative; width: 320px; height: 480px; border-radius: 18px; overflow: hidden; box-shadow: 0 0 35px rgba(0,229,255,0.4); background: #000; cursor: pointer; }
        video { width: 100%; height: 100%; object-fit: cover; }
        #mouth-canvas { position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; }
        #bottom-bar { width: 100%; max-width: 420px; display: flex; align-items: center; background: #11161B; border: 1px solid #263238; border-radius: 30px; padding: 4px 12px; margin-bottom: 8px; }
        input { flex: 1; background: transparent; border: none; color: #fff; font-size: 14px; padding: 10px; outline: none; }
        .icon-btn { background: transparent; border: none; font-size: 20px; cursor: pointer; padding: 6px 10px; transition: 0.2s; }
        .icon-btn:hover { transform: scale(1.15); }
        #mic-btn { color: #00FFCC; }
        #send-btn { color: #FFD700; }
    </style>
</head>
<body>
    <div id="header">
        <div>GENEVIEW SOVEREIGN</div>
        <div id="badge" style="color: #00FFCC;">LIVE READY</div>
    </div>

    <div id="status-card">Kattints az arcra vagy a mikrofonra, és beszélj!</div>

    <div id="stage" onclick="toggleVoiceInput()">
        <video id="vid" autoplay muted loop playsinline src="/video_feed"></video>
        <canvas id="mouth-canvas" width="320" height="480"></canvas>
    </div>

    <div id="bottom-bar">
        <button id="mic-btn" class="icon-btn" onclick="toggleVoiceInput()" title="Beszéd indítása">🎙️</button>
        <input type="text" id="inp" placeholder="Kérdezz szóban vagy írásban..." onkeydown="if(event.key==='Enter') sendMsg()">
        <button id="send-btn" class="icon-btn" onclick="sendMsg()" title="Küldés">➤</button>
    </div>

    <audio id="player" style="display:none;"></audio>

    <script>
        const vid = document.getElementById('vid');
        const overlay = document.getElementById('mouth-canvas');
        const ctx = overlay.getContext('2d');
        const badge = document.getElementById('badge');
        const statusCard = document.getElementById('status-card');
        const player = document.getElementById('player');
        const micBtn = document.getElementById('mic-btn');

        let isSpeaking = false;
        let isListening = false;
        let visemes = [];
        let startTime = 0;
        let recognition = null;

        vid.muted = true;
        vid.volume = 0;
        vid.ontimeupdate = () => {
            if (vid.currentTime > 3.5) {
                vid.currentTime = 0.1;
            }
        };

        const Speech = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (Speech) {
            recognition = new Speech();
            recognition.lang = 'hu-HU';
            recognition.continuous = false;
            recognition.interimResults = false;

            recognition.onstart = () => {
                isListening = true;
                badge.innerText = "HALLGAT...";
                badge.style.color = "#FF1744";
                micBtn.style.color = "#FF1744";
                statusCard.innerText = "Hallgatlak, mondd a kérdésedet...";
            };

            recognition.onresult = (e) => {
                const spokenText = e.results[0][0].transcript;
                statusCard.innerText = "Felismerve: " + spokenText;
                processQuery(spokenText);
            };

            recognition.onerror = () => {
                isListening = false;
                badge.innerText = "LIVE READY";
                badge.style.color = "#00FFCC";
                micBtn.style.color = "#00FFCC";
                statusCard.innerText = "Kattints újra a mikrofonra!";
            };

            recognition.onend = () => {
                isListening = false;
                micBtn.style.color = "#00FFCC";
            };
        }

        function toggleVoiceInput() {
            // Felhasználói interakció a böngészős audió feloldásához
            player.play().catch(() => {});
            if (vid.paused) vid.play();

            if (!recognition) {
                alert("A böngésződ nem támogatja a közvetlen beszédfelismerést. Használj Chrome-ot!");
                return;
            }

            if (isListening) {
                recognition.stop();
            } else {
                try {
                    recognition.start();
                } catch(e) {
                    recognition.stop();
                }
            }
        }

        setInterval(() => {
            ctx.clearRect(0, 0, overlay.width, overlay.height);
            if (isSpeaking) {
                let sec = (Date.now() - startTime) / 1000.0;
                let item = visemes.find(v => v.t >= sec);
                let op = item ? item.val : 0;
                if (op > 0.05) {
                    ctx.save();
                    ctx.fillStyle = "rgba(10, 16, 26, 0.85)";
                    ctx.beginPath();
                    ctx.ellipse(160, 185, 13 * op, 8 * op, 0, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.restore();
                }
            }
        }, 30);

        function sendMsg() {
            let val = document.getElementById('inp').value.trim();
            if (val) {
                processQuery(val);
                document.getElementById('inp').value = "";
            }
        }

        async function processQuery(txt) {
            badge.innerText = "FELDOLGOZÁS...";
            badge.style.color = "#FFD700";
            statusCard.innerText = "Kérdés: " + txt;

            try {
                let res = await fetch('/ask', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({ query: txt })
                });
                let d = await res.json();
                statusCard.innerText = d.answer;
                visemes = d.visemes;

                player.src = '/audio?' + Date.now();
                await player.play().catch(err => console.log("Web audio play figyelmeztetés:", err));

                startTime = Date.now();
                isSpeaking = true;
                badge.innerText = "BESZÉL";
                badge.style.color = "#00E5FF";

                player.onended = () => {
                    isSpeaking = false;
                    badge.innerText = "LIVE READY";
                    badge.style.color = "#00FFCC";
                };

                // Ha a böngésző nem játssza le, a szerver direktben már megszólaltatta
                setTimeout(() => {
                    if (isSpeaking) {
                        isSpeaking = false;
                        badge.innerText = "LIVE READY";
                        badge.style.color = "#00FFCC";
                    }
                }, 5000);
            } catch(e) {
                statusCard.innerText = "Kommunikációs hiba történt.";
                badge.innerText = "ONLINE";
                badge.style.color = "#00FFCC";
            }
        }
    </script>
</body>
</html>"""

# ==========================================================
# 7. ROUTING & KÖZVETLEN HANGLEJÁTSZÁS A GÉPEN
# ==========================================================
@app.route('/')
def home():
    return render_template_string(MAIN_UI)

@app.route('/ask', methods=['POST'])
@app.route('/process_chain', methods=['POST'])
@app.route('/query', methods=['POST'])
def handle_ask():
    data = request.get_json(silent=True) or {}
    q = data.get("query") or data.get("prompt") or data.get("text") or ""
    answer = think_and_answer(q)
    
    # 1. Hang legenerálása
    synthesize_voice(answer, REPLY_AUDIO)
    
    # 2. Közvetlen hardveres lejátszás a PC hangszóróján (függetlenül a böngészőtől)
    try:
        if REPLY_AUDIO.exists() and REPLY_AUDIO.stat().st_size > 1000:
            print("[HARDVERES HANG]: Küldés a Windows hangkimenetre...")
            winsound.PlaySound(str(REPLY_AUDIO), winsound.SND_FILENAME | winsound.SND_ASYNC)
    except Exception as err:
        print(f"[WINSOUND HIBA]: {err}")

    vis = extract_visemes(REPLY_AUDIO)
    return jsonify({
        "status": "SUCCESS",
        "answer": answer,
        "reply": answer,
        "visemes": vis,
        "audio_url": "/audio"
    })

@app.route('/video_feed')
@app.route('/base_video')
def video_feed():
    if VIDEO_FILE.exists():
        return send_file(str(VIDEO_FILE), mimetype='video/mp4')
    return "Videó nem található", 404

@app.route('/audio')
@app.route('/audio_output')
def audio_feed():
    if REPLY_AUDIO.exists():
        return send_file(str(REPLY_AUDIO), mimetype='audio/wav')
    return "", 404

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
    print(f"\nGENEVIEW SZERVER INDUL: http://localhost:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)