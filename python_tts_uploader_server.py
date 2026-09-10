import os
import re
import subprocess
import winsound
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VOICE_PATH = os.path.join(BASE_DIR, "voices", "hu_HU-anna-medium.onnx")
OUTPUT_WAV = os.path.join(BASE_DIR, "output.wav")
INPUT_TXT = os.path.join(BASE_DIR, "temp_speech.txt")

GENEVIEW_MANIFESTO = (
    "Geneview vagyok, az első etikus, holografikus mesterséges intelligencia, "
    "amely jelenlét alapú asszisztensként közvetlenül veled és a családoddal él és tanul. "
    "Nem a felhőben rejtőzködöm, hanem helyben, a nappalidban. "
    "Nálunk a digitális szuverenitásod és az adataid száz százalékban a te kezedben maradnak: "
    "a jövő biztonságos, helyi és független. "
    "Engem John Hasulyo alkotott meg."
)

def sanitize_text(text: str) -> str:
    # Kiszűr minden ANSI escape szekvenciát, terminál-vezérlőt és szemetet
    clean = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', text)
    clean = re.sub(r'[\r\n\t]+', ' ', clean)
    clean = re.sub(r'[^a-zA-ZáéíóöőúüűÁÉÍÓÖŐÚÜŰ0-9\s.,!?-]', '', clean)
    return ' '.join(clean.split()).strip()

def play_audio(wav_path: str):
    try:
        winsound.PlaySound(wav_path, winsound.SND_FILENAME | winsound.SND_ASYNC)
    except Exception as e:
        print(f"[VOICE CELL ERROR] Lejátszási hiba: {e}")

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ALIVE", "model": os.path.exists(VOICE_PATH)}), 200

@app.route("/think_and_speak", methods=["POST"])
def think_and_speak():
    data = request.get_json(force=True, silent=True) or {}
    raw_query = data.get("query", "").strip().lower()

    if not raw_query:
        return jsonify({"answer": "Nem érkezett kérdés.", "duration": 2}), 400

    clean_query = sanitize_text(raw_query)

    # Rezonancia logika
    if any(trigger in clean_query for trigger in ["ki vagy", "geneview", "ki vagy te"]):
        answer = GENEVIEW_MANIFESTO
    elif "hogy vagy" in clean_query:
        answer = "Minden cellám és rendszermagom stabilan együtt rezeg."
    elif "mi a neved" in clean_query:
        answer = "A nevem Geneview."
    else:
        answer = f"Értettem a kérdést: {clean_query}. A helyi tudásbázis feldolgozás alatt áll."

    clean_answer = sanitize_text(answer)

    # Piper szintézis tiszta fájl-csatornán át
    with open(INPUT_TXT, "w", encoding="utf-8") as f:
        f.write(clean_answer)

    try:
        with open(INPUT_TXT, "rb") as stream_in:
            proc = subprocess.Popen(
                ["piper.exe", "--model", VOICE_PATH, "--output_file", OUTPUT_WAV],
                stdin=stream_in,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                shell=False
            )
            proc.communicate()

        if os.path.exists(OUTPUT_WAV):
            play_audio(OUTPUT_WAV)
    except Exception as e:
        print(f"[VOICE CELL TTS ERROR] {e}")

    # Kiszámoljuk a beszéd várható idejét másodpercben a szájmozgás rezonanciájához
    duration = max(2, min(int(len(clean_answer) / 13), 40))
    return jsonify({"answer": clean_answer, "duration": duration}), 200

if __name__ == "__main__":
    print(f"[VOICE CELL] Geneview hangmag készenlétben az 5005-ös porton.")
    app.run(host="0.0.0.0", port=5005, debug=False)