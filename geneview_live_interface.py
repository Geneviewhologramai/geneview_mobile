import os
import sys
import time
import math
import wave
import struct
import threading
import subprocess
import requests
from flask import Flask, jsonify, request, render_template_string
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
AUDIO_OUT = os.path.join(BASE_DIR, "current_reply.wav")

# ==========================================
# 1. KOGNITÍV AGY + INTERNETES TUDÁS
# ==========================================
def get_cognitive_response(user_query: str) -> str:
    """Valódi válaszkeresés internetes/helyi LLM-en keresztül."""
    if not user_query.strip():
        return "Itt vagyok, figyelek rád."

    # 1. Próbálkozás a helyi Ollama motorral
    try:
        url = "http://127.0.0.1:11434/api/generate"
        payload = {
            "model": "llama3",  # vagy a telepített modellem
            "prompt": f"Te Geneview vagy, egy elegáns, intelligens női MI. Válaszolj magyarul, röviden, természetesen a következő kérdésre: {user_query}",
            "stream": False
        }
        res = requests.post(url, json=payload, timeout=8)
        if res.status_code == 200:
            ans = res.json().get("response", "").strip()
            if ans:
                return ans
    except Exception:
        pass

    # 2. Tartalék kognitív válasz, ha a helyi modell nincs betöltve
    return f"Megértettem a kérdésedet: {user_query}. A rendszerem kapcsolatban áll veled és feldolgozza az információt."

# ==========================================
# 2. MAGYAR NŐI HANG SZINTÉZIS (TTS)
# ==========================================
def synthesize_hungarian_voice(text: str, output_path: str):
    """Generálja a magyar női beszédet Piperrel vagy Sherpával."""
    piper_exe = os.path.join(BASE_DIR, "piper", "piper.exe")
    model_path = os.path.join(BASE_DIR, "hu_HU-berta-medium.onnx")

    if os.path.exists(piper_exe) and os.path.exists(model_path):
        cmd = f'echo "{text}" | "{piper_exe}" --model "{model_path}" --output_file "{output_path}"'
        subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        # Fallback Windows SAPI / PowerShell ha nincs helyi piper bináris
        ps_script = (
            f'Add-Type -AssemblyName System.Speech; '
            f'$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
            f'$synth.SetOutputToWaveFile("{output_path}"); '
            f'$synth.Speak("{text}"); '
            f'$synth.Dispose();'
        )
        subprocess.run(["powershell", "-Command", ps_script], stdout=subprocess.DEVNULL)

# ==========================================
# 3. VALÓDI SZÁJ- ÉS MIMIKASZINKRON ELEMZŐ
# ==========================================
def extract_visemes_from_audio(wav_path: str):
    """
    Kiolvassa a hanghullámok amplitúdóját, és időzített szájnyitási 
    (viséma) értékeket állít elő (0.0 = zárva, 1.0 = teljesen nyitva).
    """
    viseme_timeline = []
    try:
        with wave.open(wav_path, 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            duration = frames / float(rate)
            chunk_size = int(rate * 0.05) # 50 ms-os ablakok (20 fps szájmozgás)
            
            for i in range(0, frames, chunk_size):
                data = wf.readframes(chunk_size)
                if not data:
                    break
                # Amplitúdó számítás
                count = len(data) // 2
                shorts = struct.unpack(f"{count}h", data[:count*2])
                rms = math.sqrt(sum(s**2 for s in shorts) / (count or 1))
                mouth_open = min(1.0, max(0.0, (rms - 300) / 3500.0))
                timestamp = i / float(rate)
                viseme_timeline.append({"time": timestamp, "open": mouth_open})
    except Exception as e:
        print(f"Viseme hiba: {e}")
    return viseme_timeline

# ==========================================
# 4. HANG LEJÁTSZÁSA LÁTHATATLANUL
# ==========================================
def play_audio_silently(file_path):
    import winsound
    try:
        winsound.PlaySound(file_path, winsound.SND_FILENAME | winsound.SND_ASYNC)
    except Exception as e:
        print(f"Audio hiba: {e}")

# ==========================================
# 5. AZ INTEGRÁLT HOLOGRAM FELÜLET (HTML5 + CANVAS)
# ==========================================
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <title>GENEVIEW // SOVEREIGN HOLOGRAM</title>
    <style>
        body { margin: 0; background-color: #000; color: #fff; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; height: 100vh; overflow: hidden; }
        #header { width: 100%; display: flex; justify-content: space-between; padding: 15px 30px; box-sizing: border-box; font-size: 13px; font-weight: bold; color: #FFD700; letter-spacing: 2px; }
        #status-box { width: 85%; max-width: 700px; background: rgba(13, 27, 42, 0.85); border: 1px solid #1B4965; border-radius: 12px; padding: 12px 20px; text-align: center; font-size: 14px; margin-bottom: 10px; min-height: 40px; }
        #stage { position: relative; width: 400px; height: 520px; display: flex; justify-content: center; align-items: center; cursor: pointer; }
        #aura { position: absolute; width: 320px; height: 460px; border-radius: 50%; background: radial-gradient(circle, rgba(0, 229, 255, 0.25) 0%, rgba(0,0,0,0) 70%); transition: all 0.3s ease; }
        canvas { position: absolute; z-index: 2; }
        #bottom-bar { width: 85%; max-width: 650px; display: flex; background: #11161B; border: 1px solid #263238; border-radius: 30px; padding: 5px 15px; margin-bottom: 20px; }
        #query-input { flex: 1; background: transparent; border: none; color: #fff; font-size: 14px; padding: 10px; outline: none; }
        #send-btn { background: transparent; border: none; color: #FFD700; font-size: 18px; cursor: pointer; }
        .recording { background: radial-gradient(circle, rgba(255, 23, 68, 0.45) 0%, rgba(0,0,0,0) 70%) !important; }
    </style>
</head>
<body>
    <div id="header">
        <div>GENEVIEW // MULTI-NEXUS</div>
        <div id="state-badge" style="color: #00FFCC;">READY</div>
    </div>
    
    <div id="status-box">Geneview készenlétben áll. Kattints rám és szólj hozzám!</div>
    
    <div id="stage" onclick="startVoiceInput()">
        <div id="aura"></div>
        <canvas id="holoCanvas" width="400" height="520"></canvas>
    </div>

    <div id="bottom-bar">
        <input type="text" id="query-input" placeholder="Szólj Geneview-hoz vagy kérdezz írásban..." onkeydown="if(event.key==='Enter') sendText()">
        <button id="send-btn" onclick="sendText()">➤</button>
    </div>

    <script>
        const canvas = document.getElementById('holoCanvas');
        const ctx = canvas.getContext('2d');
        const statusBox = document.getElementById('status-box');
        const stateBadge = document.getElementById('state-badge');
        const aura = document.getElementById('aura');

        let avatarImg = new Image();
        avatarImg.src = "/avatar_image";

        let mouthOpen = 0.0;
        let eyeBlink = 0.0;
        let isSpeaking = false;
        let visemes = [];
        let speechStartTime = 0;

        // Rajzolás folyamatos ciklusban
        function render() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            if (avatarImg.complete && avatarImg.naturalWidth !== 0) {
                ctx.drawImage(avatarImg, 20, 20, 360, 480);
                
                // Valós idejű száj szinkron réteg
                if (isSpeaking && mouthOpen > 0.05) {
                    ctx.save();
                    // Száj területének dinamikus alakítása a hanghullámok alapján
                    ctx.fillStyle = "rgba(10, 25, 45, 0.75)";
                    ctx.beginPath();
                    // Száj koordinátája az arcon
                    let cx = 200, cy = 182;
                    ctx.ellipse(cx, cy, 14 * mouthOpen, 9 * mouthOpen, 0, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.restore();
                }

                // Spontán pislogás
                if (eyeBlink > 0.1) {
                    ctx.fillStyle = "rgba(180, 220, 240, 0.85)";
                    ctx.fillRect(182, 148, 12, 3);
                    ctx.fillRect(206, 148, 12, 3);
                }
            }

            // Szájmozgás frissítése a hang idősávja alapján
            if (isSpeaking) {
                let currentSec = (Date.now() - speechStartTime) / 1000.0;
                let frame = visemes.find(v => v.time >= currentSec);
                if (frame) {
                    mouthOpen = frame.open;
                } else if (currentSec > visemes[visemes.length - 1]?.time + 0.3) {
                    isSpeaking = false;
                    mouthOpen = 0;
                    stateBadge.innerText = "READY";
                    stateBadge.style.color = "#00FFCC";
                }
            }

            // Természetes pislogás logika
            if (Math.random() < 0.015 && eyeBlink === 0) {
                eyeBlink = 1.0;
                setTimeout(() => { eyeBlink = 0; }, 120);
            }

            requestAnimationFrame(render);
        }
        avatarImg.onload = () => { render(); };

        // Mikrofon bemenet böngészőből
        function startVoiceInput() {
            if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
                statusBox.innerText = "A mikrofon nem támogatott, kérlek írj lent!";
                return;
            }
            const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
            const rec = new SpeechRec();
            rec.lang = 'hu-HU';
            rec.interimResults = false;

            rec.onstart = () => {
                aura.classList.add('recording');
                stateBadge.innerText = "LISTENING";
                stateBadge.style.color = "#FF1744";
                statusBox.innerText = "Hallgatlak... Mondd a kérdésed!";
            };

            rec.onresult = (e) => {
                const text = e.results[0][0].transcript;
                processQuery(text);
            };

            rec.onerror = () => {
                aura.classList.remove('recording');
                stateBadge.innerText = "READY";
                stateBadge.style.color = "#00FFCC";
            };

            rec.onend = () => {
                aura.classList.remove('recording');
            };

            rec.start();
        }

        function sendText() {
            const input = document.getElementById('query-input');
            if (input.value.trim()) {
                processQuery(input.value.trim());
                input.value = "";
            }
        }

        async function processQuery(queryText) {
            statusBox.innerText = "Gondolkodom: " + queryText;
            stateBadge.innerText = "THINKING";
            stateBadge.style.color = "#FFD700";

            try {
                const res = await fetch('/ask', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ query: queryText })
                });
                const data = await res.json();
                
                statusBox.innerText = data.answer;
                visemes = data.visemes;
                speechStartTime = Date.now();
                isSpeaking = true;
                stateBadge.innerText = "SPEAKING";
                stateBadge.style.color = "#00E5FF";

            } catch(e) {
                statusBox.innerText = "Hiba történt a kommunikációban.";
                stateBadge.innerText = "READY";
            }
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/avatar_image')
def avatar_image():
    # Megkeresi az eredeti fotót az assets mappákban
    candidates = [
        os.path.join(BASE_DIR, "assets", "images", "geneview_avatar.png"),
        os.path.join(BASE_DIR, "assets", "geneview_avatar.png"),
        os.path.join(BASE_DIR, "geneview_avatar.png"),
    ]
    for p in candidates:
        if os.path.exists(p):
            from flask import send_file
            return send_file(p, mimetype='image/png')
    return "", 404

@app.route('/ask', methods=['POST'])
def ask():
    data = request.get_json() or {}
    query = data.get("query", "")

    # 1. Kognitív válasz generálása
    answer = get_cognitive_response(query)

    # 2. Beszéd generálása
    synthesize_hungarian_voice(answer, AUDIO_OUT)

    # 3. Száj- és mimikaszinkron kiszámítása a hullámformából
    visemes = extract_visemes_from_audio(AUDIO_OUT)

    # 4. Hang megszólaltatása csendben a háttérben
    threading.Thread(target=play_audio_silently, args=(AUDIO_OUT,), daemon=True).start()

    return jsonify({
        "answer": answer,
        "visemes": visemes
    })

if __name__ == '__main__':
    print("==================================================")
    print("GENEVIEW ÉLŐ INTERFÉSZ ELINDULT!")
    print("Nyisd meg ezt a böngésződben: http://127.0.0.1:8000")
    print("==================================================")
    app.run(host='0.0.0.0', port=8000, debug=False)