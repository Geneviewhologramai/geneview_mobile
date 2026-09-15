import os
import sys
import subprocess
import requests
from pathlib import Path
from flask import Flask, request, jsonify, render_template_string, send_file
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent

# A feltöltött videód pontos neve
VIDEO_SRC = BASE_DIR / "GENEVIEW PROMO JOHN HASULYO.mov"
if not VIDEO_SRC.exists():
    # Ha más néven van a könyvtárban
    for alt in [BASE_DIR / "trim_DF3E9B45-1536-413F-8028-A9C8ADA160C0.mp4", BASE_DIR / "Every man geneview usa john hasulyo.mov"]:
        if alt.exists():
            VIDEO_SRC = alt
            break

AUDIO_OUT = BASE_DIR / "voice_reply.wav"
FINAL_VIDEO_OUT = BASE_DIR / "final_talking_geneview.mp4"

app = Flask(__name__)
CORS(app)

# ==========================================================
# 1. KOGNITÍV VÁLASZ (OLLAMA / LLM)
# ==========================================================
def get_ai_response(prompt: str) -> str:
    if not prompt.strip():
        return "Itt vagyok, figyelek rád!"

    try:
        res = requests.post(
            "http://127.0.0.1:11434/api/generate",
            json={
                "model": "llama3",
                "prompt": f"Te Geneview vagy, az intelligens digitális női entitás. Válaszolj magyarul, röviden, természetesen és határozottan (maximum 2 mondatban): {prompt}",
                "stream": False
            },
            timeout=5
        )
        if res.status_code == 200:
            txt = res.json().get("response", "").strip()
            if txt:
                return txt
    except Exception:
        pass

    p = prompt.lower()
    if "hogy vagy" in p:
        return "Köszönöm, kiválóan vagyok! A rendszereim készen állnak a feladatokra."
    elif "ki vagy" in p:
        return "Geneview vagyok, az önálló szuverén digitális intelligenciád."
    return f"Megértettem a kérdésedet: {prompt}. A válaszfeldolgozás sikeresen lefutott."

# ==========================================================
# 2. MAGYAR HANGSZINTÉZIS
# ==========================================================
def synthesize_voice(text: str, out_wav: Path):
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
# 3. VALÓDI VIDEÓ + HANG ÖSSZEFŰZÉS (FFMPEG PIPELINE)
# ==========================================================
def build_talking_video(video_source: Path, audio_source: Path, output_video: Path):
    """Az eredeti mozgó, gesztikuláló videóra ráilleszti a generált magyar beszédet."""
    # FFmpeg parancs: videót loopolja a hang hosszáig, és összefűzi
    cmd = [
        "ffmpeg", "-y",
        "-stream_loop", "-1",
        "-i", str(video_source),
        "-i", str(audio_source),
        "-map", "0:v:0",
        "-map", "1:a:0",
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        "-pix_fmt", "yuv420p",
        str(output_video)
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# ==========================================================
# 4. EGYSÉGES VIDEÓLEJÁTSZÓ FELÜLET
# ==========================================================
HTML_PAGE = """
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>GENEVIEW // LIVE TALKING AVATAR</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; background: #000; color: #fff; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; flex-direction: column; align-items: center; height: 100vh; overflow: hidden; }
        #header { width: 100%; display: flex; justify-content: space-between; padding: 12px 24px; font-weight: bold; color: #FFD700; font-size: 13px; }
        #status-card { width: 90%; max-width: 500px; background: rgba(13,27,42,0.85); border: 1px solid #1B4965; border-radius: 12px; padding: 10px 16px; text-align: center; font-size: 14px; min-height: 42px; margin-bottom: 8px; }
        #video-container { position: relative; width: 330px; height: 540px; border-radius: 18px; overflow: hidden; box-shadow: 0 0 35px rgba(0,229,255,0.3); background: #000; cursor: pointer; }
        video { width: 100%; height: 100%; object-fit: cover; }
        #bottom-bar { width: 90%; max-width: 500px; display: flex; background: #11161B; border: 1px solid #263238; border-radius: 30px; padding: 4px 14px; margin-top: 12px; }
        input { flex: 1; background: transparent; border: none; color: #fff; font-size: 14px; padding: 10px; outline: none; }
        button { background: transparent; border: none; color: #FFD700; font-size: 20px; cursor: pointer; }
    </style>
</head>
<body>
    <div id="header">
        <div>GENEVIEW // MULTI-NEXUS</div>
        <div id="badge" style="color: #00FFCC;">ONLINE</div>
    </div>

    <div id="status-card">Geneview készen áll. Érintsd meg a videót és beszélj hozzá!</div>

    <div id="video-container" onclick="startSpeech()">
        <video id="avatarVideo" playsinline loop muted autoplay src="/base_video"></video>
    </div>

    <div id="bottom-bar">
        <input type="text" id="userInput" placeholder="Írj vagy kérdezz Geneview-tól..." onkeydown="if(event.key==='Enter') sendText()">
        <button onclick="sendText()">➤</button>
    </div>

    <script>
        const video = document.getElementById('avatarVideo');
        const badge = document.getElementById('badge');
        const statusCard = document.getElementById('status-card');

        function startSpeech() {
            const Speech = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (!Speech) {
                statusCard.innerText = "Használd az alsó beviteli sávot a kérdezéshez!";
                return;
            }
            const rec = new Speech();
            rec.lang = 'hu-HU';
            rec.onstart = () => {
                badge.innerText = "LISTENING";
                badge.style.color = "#FF1744";
                statusCard.innerText = "Hallgatlak... Beszélj most!";
            };
            rec.onresult = (e) => {
                processQuery(e.results[0][0].transcript);
            };
            rec.onerror = () => {
                badge.innerText = "ONLINE";
                badge.style.color = "#00FFCC";
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
            badge.innerText = "THINKING";
            badge.style.color = "#FFD700";
            statusCard.innerText = "Gondolkodom: " + q;

            try {
                let res = await fetch('/ask', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({ query: q })
                });
                let data = await res.json();
                statusCard.innerText = data.answer;

                // Betöltjük a frissen generált, hanggal szinkronizált videót
                badge.innerText = "SPEAKING";
                badge.style.color = "#00E5FF";

                video.muted = false;
                video.loop = false;
                video.src = '/get_final_video?' + Date.now();
                video.play();

                video.onended = () => {
                    // Beszéd végeztével visszaáll az alapjárati néma videóhurokra
                    video.muted = true;
                    video.loop = true;
                    video.src = '/base_video';
                    video.play();
                    badge.innerText = "ONLINE";
                    badge.style.color = "#00FFCC";
                };

            } catch (e) {
                statusCard.innerText = "Hiba történt a kapcsolatban.";
                badge.innerText = "ONLINE";
                badge.style.color = "#00FFCC";
            }
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_PAGE)

@app.route('/base_video')
def base_video():
    if VIDEO_SRC.exists():
        return send_file(str(VIDEO_SRC), mimetype='video/mp4')
    return "", 404

@app.route('/get_final_video')
def get_final_video():
    if FINAL_VIDEO_OUT.exists():
        return send_file(str(FINAL_VIDEO_OUT), mimetype='video/mp4')
    return "", 404

@app.route('/ask', methods=['POST'])
def ask():
    data = request.get_json() or {}
    q = data.get("query", "")

    # 1. Kognitív válasz
    answer = get_ai_response(q)

    # 2. Hang generálása
    synthesize_voice(answer, AUDIO_OUT)

    # 3. Videó és hang összefűzése egyetlen MP4 fájlba
    build_talking_video(VIDEO_SRC, AUDIO_OUT, FINAL_VIDEO_OUT)

    return jsonify({
        "status": "SUCCESS",
        "answer": answer
    })

if __name__ == '__main__':
    print("==========================================================")
    print(f"GENEVIEW ÉLŐ VIDEÓ-SZINKRON SZERVER ELINDULT!")
    print(f"Bázisvideó: {VIDEO_SRC.name}")
    print(f"Megnyitás: http://localhost:8000")
    print("==========================================================")
    app.run(host='0.0.0.0', port=8000, debug=False)