import os
import glob
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
# Közvetlen hivatkozás a te tiszta magyar mintáidra
RAW_VOICES_DIR = BASE_DIR / "voices" / "training_raw"

def get_reference_audio() -> Path:
    """Kiválasztja a legjobb minőségű női referenciahangot a gyűjteményedből."""
    # Elsődleges minták
    priority = [
        RAW_VOICES_DIR / "abigel_tiszta.wav",
        RAW_VOICES_DIR / "Absztrakció és Logika 2.wav",
        RAW_VOICES_DIR / "Családi Beszélgetések.wav"
    ]
    for p in priority:
        if p.exists():
            return p
            
    # Ha a kiemeltek nincsenek, az első elérhető wav a mappából
    all_wavs = list(RAW_VOICES_DIR.glob("*.wav"))
    if all_wavs:
        return all_wavs[0]
        
    return None

def play_geneview_voice(target_audio: Path):
    """Kizárólag a te mintakészletedből generált vagy beolvasott hangot játssza le."""
    ref = get_reference_audio()
    if ref:
        print(f"[VOICE CORE] Aktív hangminta forrás: {ref.name}")