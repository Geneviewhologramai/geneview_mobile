import os
import glob
import wave
import contextlib
import numpy as np

# Szükséges könyvtárak ellenőrzése
try:
    from pydub import AudioSegment
    from pydub.silence import split_on_silence
except ImportError:
    print("[HIBA] A pydub nincs telepítve! Futtasd: pip install pydub")
    exit(1)

# Mappa útvonalak
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "voices", "training_raw")
DATASET_DIR = os.path.join(BASE_DIR, "voices", "dataset")
WAVS_DIR = os.path.join(DATASET_DIR, "wavs")
METADATA_FILE = os.path.join(DATASET_DIR, "metadata.csv")

os.makedirs(WAVS_DIR, exist_ok=True)

print("=" * 60)
print("  GENEVIEW HANG-CELLA NEURÁLIS TANÍTÓ PIPELINE")
print("=" * 60)

def process_all_audio_files():
    # Megkeressük az ÖSSZES hangmintát a training_raw könyvtárban
    raw_files = glob.glob(os.path.join(RAW_DIR, "*.wav"))
    
    if not raw_files:
        print(f"[!] Nem található WAV fájl a következő helyen: {RAW_DIR}")
        print("Kérlek, másold be a 8 darab felvételt ebbe a mappába!")
        return

    print(f"[*] Talált nyers hangminták száma: {len(raw_files)} db.")
    
    metadata_entries = []
    total_chunks = 0

    for file_idx, file_path in enumerate(raw_files):
        file_name = os.path.basename(file_path)
        print(f"\n[+] Feldolgozás alatt ({file_idx + 1}/{len(raw_files)}): {file_name}")
        
        # Betöltés és standardizálás: Piper kompatibilis 22050Hz Mono WAV
        audio = AudioSegment.from_file(file_path)
        audio = audio.set_frame_rate(22050).set_channels(1)

        # Csendérzékelés alapú mondatvágás (min. 400ms csend mentén)
        # Ez biztosítja a tiszta mondat- és fonémaszintű tanulást
        chunks = split_on_silence(
            audio,
            min_silence_len=350,
            silence_thresh=audio.dBFS - 14,
            keep_silence=200
        )

        print(f"    -> Kivágott beszéd-szegmensek száma: {len(chunks)} db")

        for c_idx, chunk in enumerate(chunks):
            # Csak a 1.2 mp és 12 mp közötti szegmenseket tartjuk meg a stabil tanításhoz
            duration_sec = len(chunk) / 1000.0
            if 1.2 <= duration_sec <= 12.0:
                chunk_filename = f"geneview_sample_{file_idx+1:02d}_{c_idx:03d}.wav"
                chunk_path = os.path.join(WAVS_DIR, chunk_filename)
                
                # Normalizálás és mentés
                chunk = chunk.normalize()
                chunk.export(chunk_path, format="wav")
                
                # Meta bejegyzés létrehozása
                metadata_entries.append(f"{chunk_filename}|Geneview hangminta szegmens")
                total_chunks += 1

    # Metadata fájl mentése
    with open(METADATA_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(metadata_entries))

    print("\n" + "=" * 60)
    print(f"[SIKER] Az összes mintát feldolgoztuk és megtanulhatóvá tettük!")
    print(f"[*] Összes kivágott tanító szegmens: {total_chunks} db")
    print(f"[*] Kimeneti WAV mappa: {WAVS_DIR}")
    print(f"[*] Adatbázis leíró: {METADATA_FILE}")
    print("=" * 60)

if __name__ == "__main__":
    process_all_audio_files()