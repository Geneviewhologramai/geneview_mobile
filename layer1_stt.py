# C:\GENEVIEW_CORE\geneview_mobile\layer1_stt.py
import os
import io
from faster_whisper import WhisperModel

class SpeechToTextModule:
    """1. Kognitív Hallás Réteg: Whisper neurális beszéd-szöveg átalakító"""
    def __init__(self, model_size="base", device="cpu", compute_type="int8"):
        print(f"[STT INITIALIZE] Whisper modell betöltése folyamatban ({model_size})...")
        self.model = WhisperModel(model_size, device=device, compute_type=compute_type)
        print("[STT READY] A neurális hallórendszer aktív és készen áll.")

    def transcribe_audio_bytes(self, audio_bytes: bytes) -> str:
        """Közvetlen hanghullám bájtok átírása szöveggé"""
        try:
            with io.BytesIO(audio_bytes) as audio_stream:
                segments, _ = self.model.transcribe(audio_stream, beam_size=5, language="hu")
                return " ".join([seg.text for seg in segments]).strip()
        except Exception as e:
            print(f"[STT ERROR] Sikertelen átírás bájtokból: {e}")
            return ""

    def transcribe_file(self, wav_path: str) -> str:
        """Létező WAV hangfájl leirata"""
        if not os.path.exists(wav_path):
            return ""
        try:
            segments, _ = self.model.transcribe(wav_path, beam_size=5, language="hu")
            return " ".join([seg.text for seg in segments]).strip()
        except Exception as e:
            print(f"[STT ERROR] Hiba a fájl átírásakor: {e}")
            return ""