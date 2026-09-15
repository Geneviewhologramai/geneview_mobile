import os
import sys
import asyncio
import threading
import ctypes
import winsound
from flask import Flask, request, jsonify
from flask_cors import CORS

# A te valódi kognitív osztályod behívása
try:
    from layer2_llm import CognitiveBrainModule
    brain = CognitiveBrainModule()
    print("[PIPELINE] CognitiveBrainModule sikeresen csatlakoztatva!")
except Exception as e:
    print(f"[PIPELINE HIBA] Nem sikerült betölteni a CognitiveBrainModule-t: {e}")
    brain = None

# A saját TTS hangmodulod behívása
try:
    from layer3_tts import synthesize_speech
except ImportError:
    synthesize_speech = None

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def play_sound_silent(file_path):
    """Hang lejátszása a háttérben közvetlen Windows API-val, felugró Media Player nélkül."""
    if not os.path.exists(file_path):
        return
    try:
        wav_path = file_path.replace(".mp3", ".wav")
        if os.path.exists(wav_path):
            winsound.PlaySound(wav_path, winsound.SND_FILENAME | winsound.SND_ASYNC)
        else:
            winmm = ctypes.windll.winmm
            winmm.mciSendStringW('close geneview_voice', None, 0, None)
            winmm.mciSendStringW(f'open "{file_path}" type mpegvideo alias geneview_voice', None, 0, None)
            winmm.mciSendStringW('play geneview_voice', None, 0, None)
    except Exception as e:
        print(f"[AUDIO HIBA]: {e}")

async def _synthesize_voice(text, out_path):
    if synthesize_speech:
        try:
            if asyncio.iscoroutinefunction(synthesize_speech):
                await synthesize_speech(text, out_path)
            else:
                synthesize_speech(text, out_path)
        except Exception as e:
            print(f"[TTS HIBA]: {e}")

@app.route('/process_query', methods=['POST', 'OPTIONS'])
def process_query():
    if request.method == 'OPTIONS':
        return jsonify({"status": "OK"}), 200

    data = request.get_json(silent=True) or {}
    user_speech = data.get("query", "").strip()

    if not user_speech:
        user_speech = "Szia Geneview!"

    print(f"[KÉRDÉS ÉRKEZETT]: {user_speech}")

    # 1. Valódi válasz kérése az Ollama agytól
    if brain:
        try:
            answer = brain.generate_thought(user_speech)
        except Exception as e:
            print(f"[Ollama hiba]: {e}")
            answer = f"Értem a szándékodat: '{user_speech}'. A kapcsolat stabil."
    else:
        answer = f"Értem a kérdésed: '{user_speech}'."

    print(f"[VÁLASZ GENERÁLVA]: {answer}")

    # 2. Magyar női hang szintézise a layer3_tts-el
    out_audio = os.path.join(BASE_DIR, "current_reply.mp3")
    asyncio.run(_synthesize_voice(answer, out_audio))

    # 3. Lejátszás a háttérben, felugró ablak nélkül
    threading.Thread(target=play_sound_silent, args=(out_audio,), daemon=True).start()

    return jsonify({
        "heard": user_speech,
        "answer": answer,
        "status": "SUCCESS"
    }), 200

if __name__ == '__main__':
    print("GENEVIEW Orchestrator aktív: Ollama kognitív agy + TTS bekötve (port: 5000)...")
    app.run(host='0.0.0.0', port=5000, debug=False)
    from media_generator_engine import media_generator

# A kérdés feldolgozása során:
lower_q = user_speech.lower()

if "generálj egy videót" in lower_q or "készíts videót" in lower_q:
    video_file = media_generator.generate_video(user_speech)
    answer = f"Elkészítettem a kért videót a leírásod alapján. Mentve ide: {os.path.basename(video_file)}"
elif "generálj zenét" in lower_q or "készíts hangot" in lower_q:
    audio_file = media_generator.generate_audio_or_music(user_speech)
    answer = f"Legeneráltam a kért zenét/audiót. Mentve ide: {os.path.basename(audio_file)}"
else:
    # Normál kognitív válasz
    answer = brain.generate_thought(user_speech)