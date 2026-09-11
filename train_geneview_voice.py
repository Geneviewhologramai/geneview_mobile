import os
import glob
import wave
import struct

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "voices", "training_raw")
DATASET_DIR = os.path.join(BASE_DIR, "voices", "dataset")
WAVS_DIR = os.path.join(DATASET_DIR, "wavs")
METADATA_FILE = os.path.join(DATASET_DIR, "metadata.csv")

os.makedirs(WAVS_DIR, exist_ok=True)

print("=" * 60)
print("  GENEVIEW HANG-CELLA NEURALIS TANITO PIPELINE (NATIV WAV)")
print("=" * 60)

def split_wav_file(file_path, file_idx):
    with wave.open(file_path, 'rb') as w:
        n_channels = w.getnchannels()
        framerate = w.getframerate()
        n_frames = w.getnframes()
        raw_bytes = w.readframes(n_frames)

    fmt = f"<{n_frames * n_channels}h"
    samples = struct.unpack(fmt, raw_bytes)
    
    if n_channels > 1:
        mono_samples = [int((samples[i] + samples[i+1]) / 2) for i in range(0, len(samples), 2)]
    else:
        mono_samples = list(samples)

    chunk_size = int(framerate * 0.05)
    chunks = []
    current_chunk = []
    silent_windows = 0
    silence_limit = 8

    for i in range(0, len(mono_samples), chunk_size):
        window = mono_samples[i:i+chunk_size]
        if not window:
            continue
        rms = (sum(s * s for s in window) / len(window)) ** 0.5

        if rms < 300:
            silent_windows += 1
            if silent_windows >= silence_limit and len(current_chunk) > framerate * 1.2:
                chunks.append(current_chunk)
                current_chunk = []
                silent_windows = 0
        else:
            silent_windows = 0
            current_chunk.extend(window)

    if len(current_chunk) > framerate * 1.2:
        chunks.append(current_chunk)

    saved_count = 0
    metadata = []
    
    for c_idx, c_samples in enumerate(chunks):
        duration = len(c_samples) / framerate
        if 1.0 <= duration <= 12.0:
            out_name = f"geneview_sample_{file_idx+1:02d}_{c_idx+1:03d}.wav"
            out_path = os.path.join(WAVS_DIR, out_name)
            
            max_val = max(abs(s) for s in c_samples) or 1
            scale = 30000.0 / max_val
            norm_samples = [int(s * scale) for s in c_samples]
            out_bytes = struct.pack(f"<{len(norm_samples)}h", *norm_samples)

            with wave.open(out_path, 'wb') as out_w:
                out_w.setnchannels(1)
                out_w.setsampwidth(2)
                out_w.setframerate(framerate)
                out_w.writeframes(out_bytes)

            metadata.append(f"{out_name}|Geneview hangminta szegmens")
            saved_count += 1

    return saved_count, metadata

def process_all():
    raw_files = glob.glob(os.path.join(RAW_DIR, "*.wav"))
    if not raw_files:
        print(f"[!] Nem talalhato WAV fajl itt: {RAW_DIR}")
        return

    print(f"[*] Talalt nyers hangmintak: {len(raw_files)} db.")
    all_metadata = []
    total_segments = 0

    for idx, f_path in enumerate(raw_files):
        f_name = os.path.basename(f_path)
        print(f"[+] Feldolgozas: {f_name}")
        try:
            count, meta = split_wav_file(f_path, idx)
            total_segments += count
            all_metadata.extend(meta)
            print(f"    -> Szegmensek: {count} db")
        except Exception as e:
            print(f"    [HIBA] {e}")

    with open(METADATA_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(all_metadata))

    print("\n" + "=" * 60)
    print(f"[SIKER] Kesz! Osszes minta: {total_segments} db")
    print(f"[*] Mappa: {WAVS_DIR}")
    print("=" * 60)

if __name__ == "__main__":
    process_all()
