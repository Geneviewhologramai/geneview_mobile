import torch
from TTS.api import TTS

# 1. XTTS v2 modell betöltése (automatikusan letölti az első futáskor)
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Modell betöltése... Eszköz: {device}")

tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)

# 2. Beszéd generálása a saját mintád alapján
def generate_cloned_speech(text_to_speak: str, output_path: str = "output.wav"):
    tts.tts_to_file(
        text=text_to_speak,
        speaker_wav="geneview_sample.wav",  # A felvett női hangminta
        language="hu",                      # Magyar kiejtés
        file_path=output_path
    )
    print(f"A beszéd elkészült: {output_path}")

if __name__ == "__main__":
    proba_mondat = "Üdvözöllek! Dzsinvjú vagyok, a te személyes asszisztensed."
    generate_cloned_speech(proba_mondat)