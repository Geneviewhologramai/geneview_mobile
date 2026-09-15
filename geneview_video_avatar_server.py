import os
import sys
import cv2
import math
import wave
import struct
import threading
import subprocess
import requests
from pathlib import Path
from flask import Flask, request, jsonify, send_file, render_template_string
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent
VIDEO_SOURCE = BASE_DIR / "GENEVIEW PROMO JOHN HASULYO.mov"
FRAMES_DIR = BASE_DIR / "avatar_cache_frames"
CUSTOM_AVATAR_PATH = BASE_DIR / "custom_avatar.jpg"
OUTPUT_AUDIO = BASE_DIR / "current_reply.wav"

app = Flask(__name__)
CORS(app)

# Globális állapot
current_avatar_mode = "video"  # "video" vagy "custom"
custom_face_box = {"cx": 240, "cy": 250, "mouth_y": 290}

def prepare_video_cache():
    FRAMES_DIR.mkdir(parents=True, exist_ok=True)
    existing = list(FRAMES_DIR.glob("frame_*.jpg"))
    if len(existing) > 10:
        return len(existing)

    if not VIDEO_SOURCE.exists():
        return 0

    cap = cv2.VideoCapture(str(VIDEO_SOURCE))
    idx = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frame_resized = cv2.resize(frame, (480, 854))
        cv2.imwrite(str(FRAMES_DIR / f"frame_{idx:04d}.jpg"), frame_resized, [cv2.IMWRITE_JPEG_QUALITY, 85])
        idx += 1
    cap.release()
    return idx

TOTAL_FRAMES = prepare_video_cache()

def detect_face_in_custom(image_path: Path):
    """Megkeresi az arc és a száj pozícióját a feltöltött egyedi fotón."""
    global custom_face_box
    try:
        img = cv2.imread(str(image_path))
        if img is None:
            return
        h, w, _ = img.shape
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.2, 4)
        if len(faces) > 0:
            (x, y, fw, fh) = faces[0]
            custom_face_box = {
                "cx": int(x + fw / 2),
                "cy": int(y + fh / 2),
                "mouth_y": int(y + fh * 0.78)
            }
        else:
            custom_face_box = {"cx": int(w / 2), "cy": int(h * 0.4), "mouth_y": int(h * 0.52)}
    except Exception as e:
        print(f"[FACE DETECT]: {e}")

def query_intelligence(user_prompt: str) -> str:
    if not user_prompt.strip():
        return "Itt vagyok, figyelek rád."
    try:
        url = "http://127.0.0.1:11434/api/generate"
        payload = {
            "model": "llama3",
            "prompt": f"Te vagy Geneview, az elegáns MI. Válaszolj magyarul, röviden, természetesen: {user_prompt}",
            "stream": False
        }
        res = requests.post(url, json=payload, timeout=6)
        if res.status_code == 200:
            resp = res.json().get("response", "").strip()
            if resp:
                return resp
    except Exception:
        pass
    return f"Megértettem: '{user_prompt}'. A rendszer feldolgozza a gondolataidat."

def synthesize_voice(text: str, out_path: Path):
    piper_exe = BASE_DIR / "piper" / "piper.exe"
    model_path = BASE_DIR / "hu_HU-berta-medium.onnx"

    if piper_exe.exists() and model_path.exists():
        cmd = f'echo "{text}" | "{piper_exe}" --model "{model_path}" --output_file "{out_path}"'
        subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        ps_script = (
            f'Add-Type -AssemblyName System.Speech; '
            f'$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
            f'$s.SetOutputToWaveFile("{out_path}"); '
            f'$s.Speak("{text}"); $s.Dispose();'
        )
        subprocess.run(["powershell", "-Command", ps_script], stdout=subprocess.DEVNULL)

def extract_visemes(wav_path: Path):
    timeline = []
    try:
        with wave.open(str(wav_path), 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            chunk = int(rate * 0.04)
            for i in range(0, frames, chunk):
                data = wf.readframes(chunk)
                if not data:
                    break
                cnt = len(data) // 2
                shorts = struct.unpack(f"{cnt}h", data[:cnt*2])
                rms = math.sqrt(sum(s**2 for s in shorts) / (cnt or 1))
                openness = min(1.0, max(0.0, (rms - 350) / 3200.0))
                timeline.append({"t": i / float(rate), "open": round(openness, 2)})
    except Exception as e:
        print(f"Viseme hiba: {e}")
    return timeline

HTML_UI = """
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>GENEVIEW // MULTI-AVATAR</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; background: #000; color: #fff; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; flex-direction: column; align-items: center; height: 100vh; overflow: hidden; }
        #header { width: 100%; display: flex; justify-content: space-between; align-items: center; padding: 10px 20px; font-size: 13px; font-weight: 700; color: #FFD700; letter-spacing: 2px; }
        .menu-btn { background: #11161B; border: 1px solid #1B4965; color: #00E5FF; padding: 6px 12px; border-radius: 8px; cursor: pointer; font-size: 11px; font-weight: bold; }
        #response-card { width: 90%; max-width: 550px; background: rgba(13, 27, 42, 0.85); border: 1px solid #1B4965; border-radius: 12px; padding: 10px 16px; text-align: center; font-size: 13px; min-height: 42px; margin-bottom: 6px; }
        #stage { position: relative; width: 340px; height: 530px; border-radius: 16px; overflow: hidden; cursor: pointer; box-shadow: 0 0 35px rgba(0, 229, 255, 0.25); display: flex; justify-content: center; align-items: center; }
        canvas { width: 100%; height: 100%; object-fit: cover; }
        #bottom-bar { width: 90%; max-width: 550px; display: flex; background: #11161B; border: 1px solid #263238; border-radius: 30px; padding: 4px 12px; margin-top: 10px; }
        #text-input { flex: 1; background: transparent; border: none; color: #fff; font-size: 14px; padding: 10px; outline: none; }
        #send-btn { background: transparent; border: none; color: #FFD700; font-size: 20px; cursor: pointer; }
        
        /* Modal az Avatarváltáshoz */
        #modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); z-index: 100; justify-content: center; align-items: center; }
        #modal-card { background: #0D1B2A; border: 1px solid #00E5FF; border-radius: 16px; padding: 24px; width: 85%; max-width: 400px; text-align: center; }
        .modal-opt-btn { width: 100%; padding: 12px; margin: 8px 0; background: #11161B; border: 1px solid #263238; border-radius: 10px; color: #fff; font-size: 13px; cursor: pointer; }
        .modal-opt-btn:hover { border-color: #00E5FF; color: #00E5FF; }
    </style>
</head>
<body>
    <div id="header">
        <div>GENEVIEW // MULTI-NEXUS</div>
        <div>
            <button class="menu-btn" onclick="openAvatarMenu()">🎭 AVATAR VÁLTÁS</button>
            <span id="badge" style="color: #00FFCC; margin-left: 8px;">READY</span>
        </div>
    </div>

    <div id="response-card">Geneview aktív. Érintsd meg a karaktert és kérdezz tőle!</div>

    <div id="stage" onclick="startSpeechRec()">
        <canvas id="viewCanvas" width="480" height="854"></canvas>
    </div>

    <div id="bottom-bar">
        <input type="text" id="text-input" placeholder="Kérdezz a választott avatartól..." onkeydown="if(event.key==='Enter') sendPrompt()">
        <button id="send-btn" onclick="sendPrompt()">➤</button>
    </div>

    <!-- Rejtett fájlválasztó galériához/fájlokhoz és kamerához -->
    <input type="file" id="fileInput" accept="image/*" style="display:none;" onchange="uploadAvatarFile(this)">
    <input type="file" id="cameraInput" accept="image/*" capture="user" style="display:none;" onchange="uploadAvatarFile(this)">
    <audio id="audioPlayer" style="display:none;"></audio>

    <!-- Avatarváltó Menü Modal -->
    <div id="modal">
        <div id="modal-card">
            <h3 style="color:#FFD700; margin-top:0;">Válassz Avatart</h3>
            <button class="modal-opt-btn" onclick="document.getElementById('fileInput').click()">📁 Kép a Galériából / Fájlokból</button>
            <button class="modal-opt-btn" onclick="document.getElementById('cameraInput').click()">📸 Új Fotó Készítése (Kamera)</button>
            <button class="modal-opt-btn" onclick="restoreDefaultGeneview()">🔄 Visszaállítás Eredeti Geneview-ra</button>
            <button class="modal-opt-btn" style="border-color:#FF1744; color:#FF1744; margin-top:14px;" onclick="closeAvatarMenu()">Mégse</button>
        </div>
    </div>

    <script>
        const canvas = document.getElementById('viewCanvas');
        const ctx = canvas.getContext('2d');
        const badge = document.getElementById('badge');
        const respCard = document.getElementById('response-card');
        const audioPlayer = document.getElementById('audioPlayer');

        let mode = "{{ current_mode }}";
        let totalFrames = {{ total_frames }};
        let currentFrameIdx = 0;
        let isSpeaking = false;
        let visemes = [];
        let speechStartTime = 0;

        let faceCoords = {{ face_coords|tojson }};
        let customImg = new Image();
        customImg.src = "/custom_avatar_img?" + Date.now();

        let frameImages = [];
        for (let i = 0; i < Math.min(totalFrames, 60); i++) {
            let img = new Image();
            img.src = `/frame/${String(i).padStart(4, '0')}`;
            frameImages.push(img);
        }

        // Fő ciklus: mindkét avatartípust folyamatosan rendereli
        setInterval(() => {
            let sec = isSpeaking ? (Date.now() - speechStartTime) / 1000.0 : 0;
            let item = visemes.find(v => v.t >= sec);
            let open = (isSpeaking && item) ? item.open : 0;

            if (mode === "video" && frameImages.length > 0) {
                let img = frameImages[currentFrameIdx % frameImages.length];
                if (img.complete) {
                    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                    if (open > 0.05) {
                        ctx.save();
                        ctx.fillStyle = "rgba(15, 23, 42, 0.75)";
                        ctx.beginPath();
                        ctx.ellipse(240, 205, 12 * open, 8 * open, 0, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.restore();
                    }
                }
                currentFrameIdx++;
            } else if (mode === "custom") {
                if (customImg.complete && customImg.naturalWidth !== 0) {
                    ctx.drawImage(customImg, 0, 0, canvas.width, canvas.height);
                    
                    // A feltöltött archoz méretezett szájmozgás
                    if (open > 0.05) {
                        ctx.save();
                        ctx.fillStyle = "rgba(20, 20, 25, 0.8)";
                        ctx.beginPath();
                        ctx.ellipse(faceCoords.cx, faceCoords.mouth_y, 16 * open, 10 * open, 0, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.restore();
                    }
                }
            }
        }, 40);

        function openAvatarMenu() { document.getElementById('modal').style.display = 'flex'; }
        function closeAvatarMenu() { document.getElementById('modal').style.display = 'none'; }

        async function uploadAvatarFile(input) {
            if (!input.files || !input.files[0]) return;
            const file = input.files[0];
            const formData = new FormData();
            formData.append('avatar', file);

            respCard.innerText = "Új avatar betöltése és arcelemzés folyamatban...";
            closeAvatarMenu();

            try {
                const res = await fetch('/upload_avatar', { method: 'POST', body: formData });
                const data = await res.json();
                if (data.status === "SUCCESS") {
                    mode = "custom";
                    faceCoords = data.coords;
                    customImg.src = "/custom_avatar_img?" + Date.now();
                    respCard.innerText = "Az új avatar sikeresen aktiválva!";
                }
            } catch (e) {
                respCard.innerText = "Hiba történt a kép feltöltésekor.";
            }
        }

        async function restoreDefaultGeneview() {
            closeAvatarMenu();
            await fetch('/switch_mode', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({ mode: "video" })
            });
            mode = "video";
            respCard.innerText = "Visszaállítva az eredeti Geneview avatarra.";
        }

        function startSpeechRec() {
            if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
                respCard.innerText = "Használd az alsó beviteli sávot a kérdezéshez!";
                return;
            }
            const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
            const rec = new SpeechRec();
            rec.lang = 'hu-HU';

            rec.onstart = () => {
                badge.innerText = "LISTENING";
                badge.style.color = "#FF1744";
                respCard.innerText = "Hallgatlak...";
            };
            rec.onresult = (e) => {
                processQuery(e.results[0][0].transcript);
            };
            rec.onerror = () => {
                badge.innerText = "READY";
                badge.style.color = "#00FFCC";
            };
            rec.start();
        }

        function sendPrompt() {
            let val = document.getElementById('text-input').value.trim();
            if (val) {
                processQuery(val);
                document.getElementById('text-input').value = "";
            }
        }

        async function processQuery(queryText) {
            badge.innerText = "THINKING";
            badge.style.color = "#FFD700";
            respCard.innerText = "Gondolkodom: " + queryText;

            try {
                let res = await fetch('/ask', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ query: queryText })
                });
                let data = await res.json();

                respCard.innerText = data.answer;
                visemes = data.visemes;

                audioPlayer.src = '/audio_reply?' + Date.now();
                audioPlayer.play();

                speechStartTime = Date.now();
                isSpeaking = true;
                badge.innerText = "SPEAKING";
                badge.style.color = "#00E5FF";

                audioPlayer.onended = () => {
                    isSpeaking = false;
                    badge.innerText = "READY";
                    badge.style.color = "#00FFCC";
                };
            } catch(e) {
                respCard.innerText = "Kapcsolati hiba.";
                badge.innerText = "READY";
                badge.style.color = "#00FFCC";
            }
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(
        HTML_UI, 
        total_frames=TOTAL_FRAMES, 
        current_mode=current_avatar_mode,
        face_coords=custom_face_box
    )

@app.route('/upload_avatar', methods=['POST'])
def upload_avatar():
    global current_avatar_mode
    if 'avatar' not in request.files:
        return jsonify({"status": "NO_FILE"}), 400
    
    file = request.files['avatar']
    file.save(str(CUSTOM_AVATAR_PATH))
    
    # Kép optimalizálása 480x854 méretre
    img = cv2.imread(str(CUSTOM_AVATAR_PATH))
    if img is not None:
        resized = cv2.resize(img, (480, 854))
        cv2.imwrite(str(CUSTOM_AVATAR_PATH), resized)
        detect_face_in_custom(CUSTOM_AVATAR_PATH)

    current_avatar_mode = "custom"
    return jsonify({
        "status": "SUCCESS", 
        "coords": custom_face_box
    })

@app.route('/switch_mode', methods=['POST'])
def switch_mode():
    global current_avatar_mode
    data = request.get_json() or {}
    current_avatar_mode = data.get("mode", "video")
    return jsonify({"status": "SUCCESS", "mode": current_avatar_mode})

@app.route('/custom_avatar_img')
def custom_avatar_img():
    if CUSTOM_AVATAR_PATH.exists():
        return send_file(str(CUSTOM_AVATAR_PATH), mimetype='image/jpeg')
    return "", 404

@app.route('/frame/<num>')
def get_frame(num):
    path = FRAMES_DIR / f"frame_{num}.jpg"
    if path.exists():
        return send_file(str(path), mimetype='image/jpeg')
    return "", 404

@app.route('/audio_reply')
def get_audio():
    if OUTPUT_AUDIO.exists():
        return send_file(str(OUTPUT_AUDIO), mimetype='audio/wav')
    return "", 404

@app.route('/ask', methods=['POST'])
def ask():
    data = request.get_json() or {}
    q = data.get("query", "")
    answer = query_intelligence(q)
    synthesize_voice(answer, OUTPUT_AUDIO)
    visemes = extract_visemes(OUTPUT_AUDIO)
    return jsonify({"answer": answer, "visemes": visemes})

if __name__ == '__main__':
    print("GENEVIEW MULTI-AVATAR MOTOR ELINDULT -> http://localhost:8000")
    app.run(host='0.0.0.0', port=8000, debug=False)