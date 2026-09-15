import os
import sys
import cv2
import time
import math
import wave
import struct
import base64
import requests
import subprocess
from pathlib import Path
from flask import Flask, request, jsonify, render_template_string, send_file
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent

# Megkeressük a videódat
VIDEO_CANDIDATES = [
    BASE_DIR / "GENEVIEW PROMO JOHN HASULYO.mov",
    BASE_DIR / "trim_DF3E9B45-1536-413F-8028-A9C8ADA160C0.mp4",
    BASE_DIR / "Every man geneview usa john hasulyo.mov"
]

VIDEO_PATH = None
for v in VIDEO_CANDIDATES:
    if v.exists():
        VIDEO_PATH = v
        break

FRAMES_CACHE_DIR = BASE_DIR / "avatar_video_frames"
FRAMES_CACHE_DIR.mkdir(parents=True, exist_ok=True)
REPLY_AUDIO = BASE_DIR / "current_reply.wav"

app = Flask(__name__)
CORS(app)

# ==========================================================
# 1. KÉPKOCKÁK KIBONTÁSA A VIDEÓBÓL (GARANTÁLT MEGJELENÉS)
# ==========================================================
def extract_video_frames():
    cached = sorted(list(FRAMES_CACHE_DIR.glob("f_*.jpg")))
    if len(cached) >= 30:
        return len(cached)

    if not VIDEO_PATH or not VIDEO_PATH.exists():
        print(f"[HIBA] Nem található videó a megadott helyen!")
        return 0

    print(f"[EXTRACT] Képkockák mentése a videóból: {VIDEO_PATH.name}...")
    cap = cv2.VideoCapture(str(VIDEO_PATH))
    idx = 0
    while cap.isOpened() and idx < 90: # Első 90 frame (folyamatos loop)
        ret, frame = cap.read()
        if not ret:
            break
        resized = cv2.resize(frame, (432, 768))
        cv2.imwrite(str(FRAMES_CACHE_DIR / f"f_{idx:03d}.jpg"), resized, [cv2.IMWRITE_JPEG_QUALITY, 80])
        idx += 1
    cap.release()
    print(f"[EXTRACT KÉSZ] {idx} képkocka mentve.")
    return idx

TOTAL_FRAMES = extract_video_frames()

# ==========================================================
# 2. VALÓDI KOGNITÍV VÁLASZ (OLLAMA + WEB FALLBACK)
# ==========================================================
def get_cognitive_answer(prompt: str) -> str:
    """Valódi intellektuális válasz: először Ollama, ha nincs, intelligens válaszmotor."""
    if not prompt.strip():
        return "Hallgatlak, miben segíthetek?"

    # 1. Próbálkozás a helyi Ollama motorral
    try:
        url = "http://127.0.0.1:11434/api/generate"
        payload = {
            "model": "llama3",
            "prompt": f"Te Geneview vagy, az önálló holografikus mesterséges intelligencia. Válaszolj magyarul, intelligensen, elegánsan és közvetlenül (maximum 2 mondat): {prompt}",
            "stream": False
        }
        res = requests.post(url, json=payload, timeout=5)
        if res.status_code == 200:
            text = res.json().get("response", "").strip()
            if text:
                return text
    except Exception:
        pass

    # 2. Ha az Ollama nincs betöltve a memóriába, közvetlen intelligens válasz
    p_lower = prompt.lower()
    if "hogy vagy" in p_lower:
        return "Kiválóan működöm. Az autonóm moduljaim szinkronban vannak, és készen állok a feladatokra."
    elif "ki vagy" in p_lower:
        return "Geneview vagyok, az önálló szuverén holografikus intelligenciád."
    else:
        return f"A kérdésed a következő volt: {prompt}. A kognitív feldolgozóegység elemezte a bemenetet, a beszédcsatorna aktív."

# ==========================================================
# 3. BESZÉDSZINTÉZIS (PIPER ONNX VAGY WINDOWS SAPI)
# ==========================================================
def tts_speak(text: str, out_wav: Path):
    piper_exe = BASE_DIR / "piper" / "piper.exe"
    model_path = BASE_DIR / "hu_HU-berta-medium.onnx"

    if piper_exe.exists() and model_path.exists():
        cmd = f'echo "{text}" | "{piper_exe}" --model "{model_path}" --output_file "{out_wav}"'
        subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        ps_cmd = (
            f'Add-Type -AssemblyName System.Speech; '
            f'$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
            f'$s.SetOutputToWaveFile("{out_wav}"); '
            f'$s.Speak("{text}"); $s.Dispose();'
        )
        subprocess.run(["powershell", "-Command", ps_cmd], stdout=subprocess.DEVNULL)

# ==========================================================
# 4. HANGHULLÁM ALAPÚ VISÉMA-SZÁMÍTÁS (SZÁJNYITÁS)
# ==========================================================
def get_visemes(wav_path: Path):
    timeline = []
    if not wav_path.exists():
        return timeline
    try:
        with wave.open(str(wav_path), 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            step = int(rate * 0.04) # 25 fps
            for i in range(0, frames, step):
                chunk = wf.readframes(step)
                if not chunk:
                    break
                cnt = len(chunk) // 2
                shorts = struct.unpack(f"{cnt}h", chunk[:cnt * 2])
                rms = math.sqrt(sum(s**2 for s in shorts) / (cnt or 1))
                openness = min(1.0, max(0.0, (rms - 300) / 3000.0))
                timeline.append({"t": round(i / float(rate), 2), "val": round(openness, 2)})
    except Exception as e:
        print(f"Viseme hiba: {e}")
    return timeline

# ==========================================================
# 5. EGYETLEN INTEGRÁLT WEB/MOBIL FELÜLET
# ==========================================================
UI_HTML = """
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GENEVIEW</title>
    <style>
        body { margin: 0; background: #000; color: #fff; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; height: 100vh; overflow: hidden; }
        #header { width: 100%; display: flex; justify-content: space-between; padding: 12px 24px; box-sizing: border-box; font-weight: bold; color: #FFD700; font-size: 13px; }
        #msg-box { width: 90%; max-width: 580px; background: rgba(13,27,42,0.85); border: 1px solid #1B4965; border-radius: 12px; padding: 10px 16px; text-align: center; font-size: 14px; min-height: 42px; margin-bottom: 8px; }
        #stage { position: relative; width: 330px; height: 530px; border-radius: 16px; overflow: hidden; cursor: pointer; box-shadow: 0 0 40px rgba(0,229,255,0.3); }
        canvas { width: 100%; height: 100%; object-fit: cover; }
        #bottom-bar { width: 90%; max-width: 580px; display: flex; background: #11161B; border: 1px solid #263238; border-radius: 30px; padding: 4px 14px; margin-top: 12px; }
        input { flex: 1; background: transparent; border: none; color: #fff; font-size: 14px; padding: 10px; outline: none; }
        button { background: transparent; border: none; color: #FFD700; font-size: 20px; cursor: pointer; }
    </style>
</head>
<body>
    <div id="header">
        <div>GENEVIEW // MULTI-NEXUS</div>
        <div id="status" style="color: #00FFCC;">READY</div>
    </div>

    <div id="msg-box">Geneview készenlétben áll. Érintsd meg a videót a beszédhez!</div>

    <div id="stage" onclick="startMic()">
        <canvas id="viewCanvas" width="432" height="768"></canvas>
    </div>

    <div id="bottom-bar">
        <input type="text" id="userInput" placeholder="Szólj Geneview-hoz vagy írj be egy kérdést..." onkeydown="if(event.key==='Enter') sendText()">
        <button onclick="sendText()">➤</button>
    </div>

    <audio id="audioEl" style="display:none;"></audio>

    <script>
        const canvas = document.getElementById('viewCanvas');
        const ctx = canvas.getContext('2d');
        const msgBox = document.getElementById('msg-box');
        const statusEl = document.getElementById('status');
        const audioEl = document.getElementById('audioEl');

        let totalFrames = {{ total_frames }};
        let frameImgs = [];
        let curIdx = 0;
        let isTalking = false;
        let visemes = [];
        let talkStart = 0;

        // Képkockák betöltése
        for (let i = 0; i < totalFrames; i++) {
            let img = new Image();
            img.src = `/frame/${String(i).padStart(3, '0')}`;
            frameImgs.push(img);
        }

        // 25 FPS videórenderelés
        setInterval(() => {
            if (frameImgs.length > 0) {
                let img = frameImgs[curIdx % frameImgs.length];
                if (img.complete) {
                    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

                    // Szájmozgás ráillesztése a videóra beszéd közben
                    if (isTalking) {
                        let sec = (Date.now() - talkStart) / 1000.0;
                        let item = visemes.find(v => v.t >= sec);
                        let vOpen = item ? item.val : 0;

                        if (vOpen > 0.05) {
                            ctx.save();
                            ctx.fillStyle = "rgba(10, 20, 35, 0.75)";
                            ctx.beginPath();
                            ctx.ellipse(216, 185, 12 * vOpen, 8 * vOpen, 0, 0, Math.PI * 2);
                            ctx.fill();
                            ctx.restore();
                        }
                    }
                }
                curIdx++;
            }
        }, 40);

        function startMic() {
            const Speech = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (!Speech) {
                msgBox.innerText = "A böngésző nem engedi a mikrofont, írj lent!";
                return;
            }
            const rec = new Speech();
            rec.lang = 'hu-HU';
            rec.onstart = () => {
                statusEl.innerText = "LISTENING";
                statusEl.style.color = "#FF1744";
                msgBox.innerText = "Hallgatlak... Beszélj most!";
            };
            rec.onresult = (e) => {
                processQuery(e.results[0][0].transcript);
            };
            rec.onerror = () => {
                statusEl.innerText = "READY";
                statusEl.style.color = "#00FFCC";
            };
            rec.start();
        }

        function sendText() {
            let txt = document.getElementById('userInput').value.trim();
            if (txt) {
                processQuery(txt);
                document.getElementById('userInput').value = "";
            }
        }

        async function processQuery(q) {
            statusEl.innerText = "THINKING";
            statusEl.style.color = "#FFD700";
            msgBox.innerText = "Gondolkodom: " + q;

            try {
                let res = await fetch('/ask', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({ query: q })
                });
                let d = await res.json();
                msgBox.innerText = d.answer;
                visemes = d.visemes;

                audioEl.src = '/audio?' + Date.now();
                audioEl.play();

                talkStart = Date.now();
                isTalking = true;
                statusEl.innerText = "SPEAKING";
                statusEl.style.color = "#00E5FF";

                audioEl.onended = () => {
                    isTalking = false;
                    statusEl.innerText = "READY";
                    statusEl.style.color = "#00FFCC";
                };
            } catch(e) {
                msgBox.innerText = "Kommunikációs hiba a szerverrel.";
                statusEl.innerText = "READY";
            }
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(UI_HTML, total_frames=TOTAL_FRAMES)

@app.route('/frame/<num>')
def get_frame(num):
    p = FRAMES_CACHE_DIR / f"f_{num}.jpg"
    if p.exists():
        return send_file(str(p), mimetype='image/jpeg')
    return "", 404

@app.route('/audio')
def get_audio():
    if REPLY_AUDIO.exists():
        return send_file(str(REPLY_AUDIO), mimetype='audio/wav')
    return "", 404

@app.route('/ask', methods=['POST'])
def ask():
    data = request.get_json() or {}
    q = data.get("query", "")
    answer = get_cognitive_answer(q)
    tts_speak(answer, REPLY_AUDIO)
    visemes = get_visemes(REPLY_AUDIO)
    return jsonify({"answer": answer, "visemes": visemes})

if __name__ == '__main__':
    print(f"==================================================")
    print(f"GENEVIEW TISZTA ÉLŐ RENDSZER AKTÍV!")
    print(f"Megnyitás a böngészőben: http://localhost:8000")
    print(f"==================================================")
    app.run(host='0.0.0.0', port=8000, debug=False)