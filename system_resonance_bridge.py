import os
import re
import sys
import json
import time
import subprocess
import threading
from flask import Flask, request, jsonify
from flask_cors import CORS

try:
    import winsound
    HAS_WINSOUND = True
except ImportError:
    HAS_WINSOUND = False

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VOICES_DIR = os.path.join(BASE_DIR, "voices")
OUTPUT_WAV = os.path.join(BASE_DIR, "output.wav")
TEMP_SPEECH = os.path.join(BASE_DIR, "temp_speech.txt")

PIPER_MODEL = os.path.join(VOICES_DIR, "hu_HU-anna-medium.onnx")

class SystemResonanceCore:
    def __init__(self):
        self.state = "IDLE"
        self.current_text = "GENEVIEW keszenletben all."
        self.speech_end_time = 0.0
        self.lock = threading.Lock()

    def set_state(self, state, text=""):
        with self.lock:
            self.state = state
            if text:
                self.current_text = text

    def get_status(self):
        with self.lock:
            if self.state == "SPEAKING" and time.time() > self.speech_end_time:
                self.state = "IDLE"
            return {
                "state": self.state,
                "current_text": self.current_text,
                "is_speaking": self.state == "SPEAKING"
            }

resonance = SystemResonanceCore()

def sanitize_payload(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', text)
    text = re.sub(r'[\r\n\t]+', ' ', text)
    text = re.sub(r'[^a-zA-ZáéíóöőúüűÁÉÍÓÖŐÚÜŰ0-9\s.,!?-]', '', text)
    return ' '.join(text.split()).strip()

def play_audio_async(wav_file: str, duration_sec: float):
    resonance.speech_end_time = time.time() + duration_sec
    resonance.set_state("SPEAKING")

    def _worker():
        if HAS_WINSOUND and os.path.exists(wav_file):
            try:
                winsound.PlaySound(wav_file, winsound.SND_FILENAME)
            except Exception as e:
                print(f"[AUDIO HIBA] {e}")
        resonance.set_state("IDLE")

    threading.Thread(target=_worker, daemon=True).start()

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ALIVE",
        "piper_ready": os.path.exists(PIPER_MODEL),
        "voices_dir": os.path.exists(VOICES_DIR)
    }), 200

@app.route("/sync_state", methods=["GET"])
def sync_state():
    return jsonify(resonance.get_status()), 200

@app.route("/think_and_speak", methods=["POST"])
def think_and_speak():
    data = request.get_json(force=True, silent=True) or {}
    query = sanitize_payload(data.get("query", ""))

    if not query:
        return jsonify({"answer": "Nem erkezett ervenyes keres.", "duration": 2}), 400

    resonance.set_state("THINKING", "Rezonancia folyamatban...")

    sample_file = None
    lower_q = query.lower()

    if any(k in lower_q for k in ["szuverenitas", "ki vagy", "geneview"]):
        answer = "Geneview vagyok, az onallo, etikus holografikus mesterseges intelligencia."
        duration = 6.0
    elif any(k in lower_q for k in ["innovacio", "uttoro"]):
        answer = "Amit itt csinalunk, az nem egyszeru javitas, hanem tiszta uttoro innovacio."
        duration = 5.0
    else:
        answer = f"Ertelemeztem a kerest: {query}."
        duration = max(2.5, len(answer) / 14.0)

    clean_answer = sanitize_payload(answer)
    resonance.set_state("SPEAKING", clean_answer)

    return jsonify({
        "answer": clean_answer,
        "duration": int(duration),
        "status": "PROCESSED"
    }), 200

if __name__ == "__main__":
    print("[SYSTEM RESONANCE] Kiszolgalo keszenletben az 5005-os porton.")
    app.run(host="127.0.0.1", port=5005, debug=False)
