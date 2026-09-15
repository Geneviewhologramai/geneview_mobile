import os
import time
import torch
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
GENERATED_DIR = BASE_DIR / "generated_media"
GENERATED_DIR.mkdir(parents=True, exist_ok=True)

class GeneviewMediaGenerator:
    """
    Nyílt forráskódú MI Média Generátor:
    - Text-to-Video: Diffusers Text-to-Video / AnimateDiff
    - Text-to-Audio / Music: Audiocraft MusicGen / AudioGen
    """
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self._video_pipe = None
        self._music_model = None

    def _load_video_pipeline(self):
        if self._video_pipe is None:
            try:
                from diffusers import DiffusionPipeline
                from diffusers.utils import export_to_video
                print("[MEDIA ENGINE] Nyílt forráskódú videómodell betöltése...")
                # Alapértelmezett DAMO / ModelScope text-to-video vagy AnimateDiff
                self._video_pipe = DiffusionPipeline.from_pretrained(
                    "damo-vilab/text-to-video-ms-1.7b", 
                    torch_dtype=torch.float16 if self.device == "cuda" else torch.float32
                ).to(self.device)
            except Exception as e:
                print(f"[MEDIA ENGINE] Diffusers betöltési figyelmeztetés: {e}")
                self._video_pipe = "fallback"

    def _load_audio_pipeline(self):
        if self._music_model is None:
            try:
                from audiocraft.models import MusicGen
                print("[MEDIA ENGINE] Audiocraft MusicGen modell betöltése...")
                self._music_model = MusicGen.get_pretrained('facebook/musicgen-small')
            except Exception as e:
                print(f"[MEDIA ENGINE] Audiocraft figyelmeztetés: {e}")
                self._music_model = "fallback"

    def generate_video(self, prompt: str, num_frames: int = 16) -> str:
        """Kért videó generálása szöveges leírás alapján."""
        timestamp = int(time.time())
        out_path = GENERATED_DIR / f"geneview_video_{timestamp}.mp4"
        print(f"[MEDIA ENGINE] Videó generálása: '{prompt}'...")

        self._load_video_pipeline()

        if self._video_pipe and self._video_pipe != "fallback":
            try:
                from diffusers.utils import export_to_video
                video_frames = self._video_pipe(prompt, num_frames=num_frames).frames[0]
                export_to_video(video_frames, str(out_path))
                return str(out_path)
            except Exception as e:
                print(f"[MEDIA ENGINE] Diffusers futási hiba: {e}")

        # Fallback OpenCV / PIL szintézis, ha nincs letöltött checkpoint vagy kevés a VRAM
        import cv2
        import numpy as np
        fps = 8
        width, height = 384, 384
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(str(out_path), fourcc, fps, (width, height))
        
        for i in range(num_frames):
            frame = np.zeros((height, width, 3), dtype=np.uint8)
            # Pulzáló fényhatás és felirat
            color_val = int(120 + 100 * np.sin(i / 2.0))
            cv2.circle(frame, (width // 2, height // 2), 70 + i * 2, (0, color_val, 255), -1)
            cv2.putText(frame, "GENEVIEW AI GENERATION", (20, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
            cv2.putText(frame, prompt[:25], (20, 340), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 200), 1)
            out.write(frame)
        out.release()
        return str(out_path)

    def generate_audio_or_music(self, prompt: str, duration_sec: int = 5) -> str:
        """Kért zene vagy hangeffekt generálása nyílt forráskódból."""
        timestamp = int(time.time())
        out_path = GENERATED_DIR / f"geneview_sound_{timestamp}.wav"
        print(f"[MEDIA ENGINE] Audió/Zene generálása: '{prompt}' ({duration_sec}s)...")

        self._load_audio_pipeline()

        if self._music_model and self._music_model != "fallback":
            try:
                import torchaudio
                self._music_model.set_generation_params(duration=duration_sec)
                wav = self._music_model.generate([prompt])
                torchaudio.save(str(out_path), wav[0].cpu(), sample_rate=self._music_model.sample_rate)
                return str(out_path)
            except Exception as e:
                print(f"[MEDIA ENGINE] Audiocraft generálási hiba: {e}")

        # Fallback szintetizált szinusz / akkord zenei hullámforma
        import wave
        import struct
        import math
        sample_rate = 22050
        n_samples = int(sample_rate * duration_sec)
        with wave.open(str(out_path), 'w') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sample_rate)
            for i in range(n_samples):
                t = i / sample_rate
                # Két frekvenciás harmónia (A4 + E5 akkord)
                val = 0.5 * math.sin(2 * math.pi * 440.0 * t) + 0.3 * math.sin(2 * math.pi * 659.25 * t)
                val *= math.exp(-t / 3.0)  # Lefutás
                wf.writeframes(struct.pack('h', int(val * 32767)))
        return str(out_path)

# Globális singleton példány
media_generator = GeneviewMediaGenerator()