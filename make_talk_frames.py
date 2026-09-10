import os
from PIL import Image, ImageDraw, ImageFilter

base_dir = os.path.dirname(os.path.abspath(__file__))
# Megkeressük az eredeti képet az assets/images vagy a gyökér mappában
src_path = os.path.join(base_dir, "assets", "images", "Geneview.png")
if not os.path.exists(src_path):
    src_path = os.path.join(base_dir, "Geneview.png")

target_folder = os.path.join(base_dir, "assets", "images")
os.makedirs(target_folder, exist_ok=True)
dst_talk_1 = os.path.join(target_folder, "Geneview_talk_1.png")
dst_talk_2 = os.path.join(target_folder, "Geneview_talk_2.png")

img = Image.open(src_path).convert("RGBA")
w, h = img.size

# --- 1. KÉPKOCKA: Geneview_talk_1.png (félig nyitott száj, beszéd kezdete) ---
talk1 = img.copy()
# A száj körüli arányos koordináták az arc geometriája alapján
mouth_x1 = int(w * 0.47)
mouth_x2 = int(w * 0.53)
mouth_y1 = int(h * 0.175)
mouth_y2 = int(h * 0.190)

overlay1 = Image.new("RGBA", img.size, (0, 0, 0, 0))
draw1 = ImageDraw.Draw(overlay1)
# Belső szájüreg árnyék + enyhe holografikus mélység
draw1.ellipse([mouth_x1, mouth_y1, mouth_x2, mouth_y2], fill=(15, 30, 45, 230))
# Finom alsó ajak eltolás
draw1.arc([mouth_x1 - 2, mouth_y1, mouth_x2 + 2, mouth_y2 + 2], start=0, end=180, fill=(180, 230, 255, 180), width=2)
overlay1 = overlay1.filter(ImageFilter.GaussianBlur(radius=0.8))
talk1.alpha_composite(overlay1)
talk1.save(dst_talk_1)
print(f"Létrehozva: {dst_talk_1}")

# --- 2. KÉPKOCKA: Geneview_talk_2.png (nyitott száj, magánhangzók) ---
talk2 = img.copy()
mouth2_y1 = int(h * 0.172)
mouth2_y2 = int(h * 0.198)

overlay2 = Image.new("RGBA", img.size, (0, 0, 0, 0))
draw2 = ImageDraw.Draw(overlay2)
draw2.ellipse([mouth_x1 - 2, mouth2_y1, mouth_x2 + 2, mouth2_y2], fill=(10, 25, 40, 250))
# Belső fog/hologram fényvonalak
draw2.line([mouth_x1 + 2, mouth2_y1 + 3, mouth_x2 - 2, mouth2_y1 + 3], fill=(210, 245, 255, 220), width=1)
overlay2 = overlay2.filter(ImageFilter.GaussianBlur(radius=0.6))
talk2.alpha_composite(overlay2)
talk2.save(dst_talk_2)
print(f"Létrehozva: {dst_talk_2}")