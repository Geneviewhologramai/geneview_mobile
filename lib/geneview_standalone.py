import os
import subprocess
import string
import winsound
import tkinter as tk
from tkinter import font
from PIL import Image, ImageTk
from web_intelligence import fetch_web_knowledge

GENEVIEW_MANIFESTO = (
    "Geneview vagyok, az első etikus, holografikus mesterséges intelligencia, "
    "amely jelenlét-alapú asszisztensként közvetlenül veled és a családoddal él és tanul. "
    "Nem a felhőben rejtőzködöm, hanem helyben, a nappalidban, mert az adataidnak "
    "soha többé nem szabad kiszolgáltatottá válniuk a felhőóriások számára. "
    "Nem virtuális valóság szemüveg vagyok, hanem valódi jelenlét: egy klasszikus Art Deco készülékből "
    "harminc, hatvan vagy akár kilencven centiméteres élethű holografikus vetítéssel jelenek meg a térben. "
    "Nem zárlak el a külvilágtól, hanem a családi élet szerves részévé válok mint egy családtag, "
    "nem csupán egy algoritmus. "
    "A jövő nem egy elszigetelt buborék, hanem közös tér. Nálunk a digitális szuverenitásod "
    "és az adataid száz százalékban a te kezedben maradnak: a jövő biztonságos, helyi és független. "
    "Ezen a táblán te vagy a mester. "
    "Engem egyébként John Hasulyo alkotott meg, neki köszönhetően születtem meg."
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VOICE_MODEL = os.path.join(BASE_DIR, "voices", "hu_HU-anna-medium.onnx")
OUTPUT_WAV = os.path.join(BASE_DIR, "output.wav")
AVATAR_PATH = os.path.join(BASE_DIR, "assets", "images", "Geneview.png")

def speak_direct(text):
    try:
        cmd = ["piper", "--model", VOICE_MODEL, "--output_file", OUTPUT_WAV]
        p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8")
        p.communicate(input=text)
        if os.path.exists(OUTPUT_WAV):
            winsound.PlaySound(OUTPUT_WAV, winsound.SND_FILENAME | winsound.SND_ASYNC)
    except Exception as e:
        print(f"TTS hiba: {e}")

def process_query(raw_query):
    clean = raw_query.lower().translate(str.maketrans("", "", string.punctuation)).strip()
    identity_triggers = ["ki vagy", "ki vagy te", "te ki vagy", "ki vagyok", "geneview", "ki vagy te tulajdonkeppen"]
    if any(t in clean for t in identity_triggers):
        return GENEVIEW_MANIFESTO
    elif "hogy vagy" in clean:
        return "Minden rendszerem stabilan működik, készen állok a feladatokra."
    elif "mi a neved" in clean or "hogy hivnak" in clean:
        return "A nevem Geneview."
    else:
        return fetch_web_knowledge(clean)

# GUI Felépítése
root = tk.Tk()
root.title("GENEVIEW // MULTI-NEXUS")
root.geometry("800x850")
root.configure(bg="black")

header = tk.Label(root, text="GENEVIEW // SYSTEM READY", fg="#00FFAA", bg="black", font=("Consolas", 11, "bold"))
header.pack(pady=10)

bubble = tk.Label(root, text="Geneview vagyok. Készen állok a feladatokra.", fg="white", bg="#0F1A1C",
                  wraplength=650, justify="center", padx=15, pady=12, font=("Segoe UI", 11))
bubble.pack(fill="x", padx=40, pady=10)

if os.path.exists(AVATAR_PATH):
    img = Image.open(AVATAR_PATH)
    img.thumbnail((360, 520))
    photo = ImageTk.PhotoImage(img)
    avatar_label = tk.Label(root, image=photo, bg="black")
    avatar_label.image = photo
    avatar_label.pack(pady=10)

def on_send(event=None):
    q = entry.get().strip()
    if not q:
        return
    entry.delete(0, tk.END)
    header.config(text="GENEVIEW ELEMEZ...", fg="#FFD700")
    root.update()

    answer = process_query(q)
    bubble.config(text=answer)
    header.config(text="GENEVIEW BESZÉL...", fg="#D4AF37")
    root.update()

    speak_direct(answer)
    header.config(text="GENEVIEW // SYSTEM READY", fg="#00FFAA")

bottom_frame = tk.Frame(root, bg="black")
bottom_frame.pack(side="bottom", fill="x", padx=30, pady=20)

entry = tk.Entry(bottom_frame, bg="#111417", fg="white", insertbackground="white", font=("Segoe UI", 12))
entry.pack(side="left", fill="x", expand=True, ipady=8, padx=(0, 10))
entry.bind("<Return>", on_send)

send_btn = tk.Button(bottom_frame, text="Küldés", bg="#D4AF37", fg="black", font=("Segoe UI", 10, "bold"), command=on_send)
send_btn.pack(side="right", ipadx=10, ipady=4)

root.mainloop()