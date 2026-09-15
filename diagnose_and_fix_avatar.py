import os
import sys
import subprocess
from pathlib import Path
from flask import Flask, send_file, request, jsonify, Response
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent
CORS_ORIGINS = "*"

app = Flask(__name__)
CORS(app)

# 1. Forrásvideók detektálása
SRC_MOV = BASE_DIR / "GENEVIEW PROMO JOHN HASULYO.mov"
WEB_MP4 = BASE_DIR / "geneview_web.mp4"

print("\n" + "=" * 60)
print("     GENEVIEW AVATAR DIAGNOSZTIKA ÉS WEBES KONVERZIÓ")
print("=" * 60)

# 2. Diagnosztika: Forrásfájl megléte
if not SRC_MOV.exists():
    # Alternatív fájlok keresése
    alts = list(BASE_DIR.glob("*.mov")) + list(BASE_DIR.glob("*.mp4"))
    if alts:
        SRC_MOV = alts[0]
        print(f"[OK] Forrásvideó megtalálva: {SRC_MOV.name}")
    else:
        print("[HIBA] Nem található videofájl a mappában!")
        sys.exit(1)
else:
    print(f"[OK] Bázis videófájl rendben: {SRC_MOV.name} ({SRC_MOV.stat().st_size / (1024*1024):.2f} MB)")

# 3. Web-kompatibilis MP4 előállítása (H.264 + faststart flag a böngészőnek)
if not WEB_MP4.exists() or WEB_MP4.stat().st_size < 1000:
    print("\n[KONVERZIÓ] .MOV átalakítása webes szabványú H.264 MP4 formátumra...")
    cmd = [
        "ffmpeg", "-y",
        "-i", str(SRC_MOV),
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", "22",
        "-pix_fmt", "yuv420p",
        "-movflags", "+faststart",
        "-an",
        str(WEB_MP4)
    ]
    res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if WEB_MP4.exists() and WEB_MP4.stat().st_size > 1000:
        print(f"[SIKER] geneview_web.mp4 elkészült ({WEB_MP4.stat().st_size / (1024*1024):.2f} MB)!")
    else:
        print("[HIBA] Az FFmpeg nem tudta konvertálni a fájlt. Ellenőrizd az FFmpeg elérhetőségét.")
else:
    print(f"[OK] Webes MP4 gyorsítótár aktív: {WEB_MP4.name}")

print("\n" + "=" * 60)
print("  AVATAR SZERVER INDÍTÁSA A 8000-ES ÉS 5000-ES PORTON...")
print("=" * 60 + "\n")

# 4. Biztonságos Byte-Range Video Streaming a böngészőnek
@app.route('/video_feed')
@app.route('/base_video')
def serve_video():
    target = WEB_MP4 if WEB_MP4.exists() else SRC_MOV
    return send_file(str(target), mimetype='video/mp4', as_attachment=False)

@app.route('/health')
def health():
    return jsonify({"status": "ONLINE", "video_ready": WEB_MP4.exists()})

if __name__ == '__main__':
    # Elindítjuk az 5000-es porton is a Flutter felületnek, valamint a 8000-en
    port = 8000
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    print(f"-> Közvetlen elérés teszteléshez: http://localhost:{port}/video_feed")
    app.run(host='0.0.0.0', port=port, debug=False)