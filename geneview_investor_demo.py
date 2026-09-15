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
from pathlib import Path
from flask import Flask, request, jsonify, send_file, render_template_string
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent

# ==========================================================
# 1. KOGNITÍV CHRONOS ÓRA (BELSŐ IDŐÉRZÉK)
# ==========================================================
class SovereignChronos:
    NAPOK = ["hétfő", "kedd", "szerda", "csütörtök", "péntek", "szombat", "vasárnap"]
    HONAPOK = [
        "január", "február", "március", "április", "május", "június",
        "július", "augusztus", "szeptember", "október", "november", "december"
    ]
    NEVNAPOK = {
        (9, 14): "Szeréna és Roxána",
        (9, 15): "Enikő és Melitta",
        (9, 16): "Edit",
        (9, 17): "Zsófia"
    }

    @classmethod
    def get_time_answer(cls, q_norm: str) -> str:
        now = datetime.datetime.now()
        nap = cls.NAPOK[now.weekday()]
        honap = cls.HONAPOK[now.month - 1]
        nevnap = cls.NEVNAPOK.get((now.month, now.day), "a mai ünnepeltek")

        if any(k in q_norm for k in ["hany ora", "mennyi az ido", "pontos ido"]):
            return f"A pontos idő {now.strftime('%H:%M')}."
        if any(k in q_norm for k in ["milyen nap", "hanyadika", "datum"]):
            return f"Ma {now.year}. {honap} {now.day}., {nap} van."
        if any(k in q_norm for k in ["nevnap", "ki unnepli"]):
            return f"A mai napon {nevnap} névnapját ünnepeljük."
        if any(k in q_norm for k in ["milyen ev", "melyik ev"]):
            return f"{now.year}-t írunk."
        return f"Ma {now.year}. {honap} {now.day}., {nap} van, az idő pedig {now.strftime('%H:%M')}."

# ==========================================================
# 2. VALÓS IDEJŰ WEBKERESŐ (DUCKDUCKGO RAG)
# ==========================================================
def fetch_web_context(query: str) -> str:
    print(f"\n[DEMO BUS] Webes keresés indítása: '{query}'...")
    snippets = []
    try:
        from duckduckgo_search import DDGS
        with DDGS() as ddgs:
            for r in ddgs.text(query, region='hu-hu', max_results=3):
                snippets.append(f"{r.get('title', '')}: {r.get('body', '')}")
    except Exception as e:
        print(f"[DDG WARNING]: {e}")

    if not snippets:
        try:
            url = f"https://api.duckduckgo.com/?q={requests.utils.quote(query)}&format=json&no_html=1"
            res = requests.get(url, timeout=3, headers={"User-Agent": "GeneviewSovereign/1.0"})
            if res.status_code == 200:
                abstract = res.json().get("AbstractText", "")
                if abstract:
                    snippets.append(abstract)
        except Exception:
            pass

    return "\n".join(snippets) if snippets else "Nincs közvetlen találat."

# ==========================================================
# 3. KOGNITÍV AGY (SZÁNDÉK-ROUTER ÉS LLM SZINTÉZIS)
# ==========================================================
def cognitive_reasoning(query: str) -> str:
    q_raw = query.strip()
    accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ö': 'o', 'ő': 'o', 'ú': 'u', 'ü': 'u', 'ű': 'u'}
    q_norm = "".join(accents.get(c, c) for c in q_raw.lower())

    # 1. Szándék: Idő / Dátum / Névnap
    time_keys = ["hany ora", "mennyi az ido", "pontos ido", "milyen nap", "hanyadika", "datum", "milyen ev", "nevnap"]
    if any(k in q_norm for k in time_keys):
        return SovereignChronos.get_time_answer(q_norm)

    # 2. Szándék: Identitás / Alapvető Geneview profil
    if any(k in q_norm for k in ["ki vagy", "mi a neved", "mi vagy"]):
        return "Geneview vagyok, az önálló, szuverén digitális intelligenciád és jelenléted."

    # 3. Szándék: Általános intellektuális kérdés -> DuckDuckGo + LLM
    web_data = fetch_web_context(q_raw)
    now = datetime.datetime.now()
    chronos_str = f"{now.year}. {SovereignChronos.HONAPOK[now.month-1]} {now.day}., {SovereignChronos.NAPOK[now.weekday()]}"

    sys_instruction = (
        "Te Geneview vagy: egy magas intellektusú, elegáns, szuverén mesterséges intelligencia személyiség. "
        f"A valós, hiteles mai dátum: {chronos_str}. "
        "A kapott internetes kontextus alapján válaszolj pontosan, logikusan, maximum 2 kerek magyar mondatban. "
        "Kerüld a gépies sablonokat, határozottan és intelligensen fogalmazz!"
    )

    prompt = f"KÉRDÉS: {q_raw}\n\nINTERNETES ADATOK:\n{web_data}\n\nÖsszegzett válaszod:"

    try:
        res = requests.post(
            "http://127.0.0.1:11434/api/generate",
            json={
                "model": "llama3",
                "system": sys_instruction,
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": 0.3}
            },
            timeout=7
        )
        if res.status_code == 200:
            txt = res.json().get("response", "").strip()
            if txt:
                return txt
    except Exception as e:
        print(f"[LLM WARNING]: {e}")

    # Fallback logikai kinyerés
    if "Nincs közvetlen" not in web_data:
        first = web_data.splitlines()[0]
        return f"A rendelkezésre álló adatok alapján: {first}"
    return f"A kérdésedet feldolgoztam. Az intellektuális hálózatom készen áll a feladatra."

# ==========================================================
# 4. HANGSZINTÉZIS ÉS VISÉMA MOTOR
# ==========================================================
AUDIO_FILE = BASE_DIR / "current_reply.wav"
PIPER_EXE = BASE_DIR / "piper" / "piper.exe"
MODEL_PATH = BASE_DIR / "hu_HU-berta-medium.onnx"

def synthesize_voice(text: str):
    if PIPER_EXE.exists() and MODEL_PATH.exists():
        cmd = f'echo "{text}" | "{PIPER_EXE}" --model "{MODEL_PATH}" --output_file "{AUDIO_FILE}"'
        subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if AUDIO_FILE.exists() and AUDIO_FILE.stat().st_size > 1000:
            return

    # Windows SAPI Női hang fallback
    ps = (
        f'Add-Type -AssemblyName System.Speech; '
        f'$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
        f'$v = $s.GetInstalledVoices() | Where-Object {{ $_.VoiceInfo.Gender -eq "Female" }} | Select-Object -First 1; '
        f'if ($v) {{ $s.SelectVoice($v.VoiceInfo.Name) }}; '
        f'$s.SetOutputToWaveFile("{AUDIO_FILE}"); '
        f'$s.Speak("{text}"); $s.Dispose();'
    )
    subprocess.run(["powershell", "-Command", ps], stdout=subprocess.DEVNULL)

def extract_visemes():
    vis = []
    if not AUDIO_FILE.exists():
        return vis
    try:
        with wave.open(str(AUDIO_FILE), 'rb') as wf:
            frames, rate = wf.getnframes(), wf.getframerate()
            step = int(rate * 0.04)
            for i in range(0, frames, step):
                chunk = wf.readframes(step)
                if not chunk:
                    break
                cnt = len(chunk) // 2
                s = struct.unpack(f"{cnt}h", chunk[:cnt*2])
                rms = math.sqrt(sum(x**2 for x in s) / (cnt or 1))
                op = min(1.0, max(0.0, (rms - 250) / 2600.0))
                vis.append({"t": round(i / float(rate), 2), "val": round(op, 2)})
    except Exception:
        pass
    return vis

# ==========================================================
# 5. UNIFORM DISPATCHER (PORT 5000 ÉS 8000 KOMPATIBILITÁS)
# ==========================================================
app = Flask(__name__)
CORS(app)

# Videó detektálás
video_candidates = [
    BASE_DIR / "GENEVIEW PROMO JOHN HASULYO.mov",
    BASE_DIR / "geneview_web.mp4",
    BASE_DIR / "trim_DF3E9B45-1536-413F-8028-A9C8ADA160C0.mp4"
]
active_video = next((v for v in video_candidates if v.exists() and v.stat().st_size > 1000), None)

@app.route('/ask', methods=['POST'])
@app.route('/process_chain', methods=['POST'])
@app.route('/query', methods=['POST'])
def handle_incoming_query():
    data = request.get_json(silent=True) or {}
    q = data.get("query") or data.get("prompt") or data.get("text") or ""
    
    answer = cognitive_reasoning(q)
    synthesize_voice(answer)
    vis = extract_visemes()

    return jsonify({
        "status": "SUCCESS",
        "answer": answer,
        "reply": answer,
        "visemes": vis,
        "audio_url": "/audio"
    })

@app.route('/video_feed')
@app.route('/base_video')
def serve_video():
    if active_video and active_video.exists():
        mtype = 'video/mp4' if str(active_video).endswith('.mp4') else 'video/quicktime'
        return send_file(str(active_video), mimetype=mtype)
    return "Videó forrás hiányzik", 404

@app.route('/audio')
@app.route('/audio_output')
def serve_audio():
    if AUDIO_FILE.exists():
        return send_file(str(AUDIO_FILE), mimetype='audio/wav')
    return "", 404

@app.route('/')
def web_ui():
    html_file = BASE_DIR / "index.html"
    if html_file.exists():
        return send_file(str(html_file))
    return "Geneview Sovereign Core Online"

if __name__ == '__main__':
    # Alapértelmezetten a Flutter által használt 5000-es porton fut,
    # de argumentumként a 8000-es is megadható.
    port = 5000
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    print("\n" + "=" * 60)
    print(f"  GENEVIEW BEFEKTETŐI DEMÓ MOTOR ONLINE: PORT {port}")
    print(f"  Aktív videó: {active_video.name if active_video else 'FIGYELMEZTETÉS: Videó nincs bemásolva!'}")
    print("=" * 60 + "\n")
    app.run(host='0.0.0.0', port=port, debug=False)