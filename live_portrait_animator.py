# C:\GENEVIEW_CORE\geneview_mobile\live_portrait_animator.py
import cv2
import mediapipe as mp
import numpy as np
import time
import math
import os
import threading
from flask import Flask, Response

app = Flask(__name__)

# Kép elérési útja
BASE_IMAGE_PATH = os.path.abspath("assets/images/Geneview.png")

class FaceAnimator:
    def __init__(self, image_path):
        self.image_path = image_path
        self.original_img = cv2.imread(image_path)
        if self.original_img is None:
            raise FileNotFoundError(f"A kép nem található: {image_path}")
        
        self.h, self.w, _ = self.original_img.shape
        self.is_speaking = False
        self.speech_end_time = 0
        self.lock = threading.Lock()
        
        # Pislogási időzítő
        self.last_blink_time = time.time()
        self.blink_duration = 0.18  # másodperc
        self.blink_interval = 3.5   # átlagosan 3.5 másodpercenként pislog

    def start_speaking(self, duration_sec):
        """Beszéd és szájmozgás indítása adott időtartamra"""
        with self.lock:
            self.is_speaking = True
            self.speech_end_time = time.time() + duration_sec

    def generate_frame(self):
        now = time.time()
        with self.lock:
            if self.is_speaking and now > self.speech_end_time:
                self.is_speaking = False
            speaking = self.is_speaking

        # Másolat készítése a képkockához
        frame = self.original_img.copy()

        # 1. SZÁJMOZGÁS (Procedurális anatómiai deformáció)
        if speaking:
            # 12-14 Hz-es természetes beszédmodulációs frekvencia
            mouth_open_ratio = (math.sin(now * 14.0) + 1.0) / 2.0  # 0.0 és 1.0 között
            
            # Arc alsó harmadának (ajkak területének) célzott vertikális nyújtása
            # Egy tipikus portrén a száj magassága a magasság 65-75%-a között található
            mouth_y_start = int(self.h * 0.64)
            mouth_y_end = int(self.h * 0.76)
            mouth_x_start = int(self.w * 0.38)
            mouth_x_end = int(self.w * 0.62)

            mouth_roi = frame[mouth_y_start:mouth_y_end, mouth_x_start:mouth_x_end]
            if mouth_roi.size > 0:
                # Vertikális skálázás az ajkak nyitásához
                scale_y = 1.0 + (mouth_open_ratio * 0.28)
                new_h = int(mouth_roi.shape[0] * scale_y)
                resized_mouth = cv2.resize(mouth_roi, (mouth_roi.shape[1], new_h), interpolation=cv2.INTER_LINEAR)
                
                # Visszaillesztés finom átmenettel
                h_diff = new_h - mouth_roi.shape[0]
                frame[mouth_y_start:mouth_y_end, mouth_x_start:mouth_x_end] = resized_mouth[:mouth_roi.shape[0], :]

        # 2. PISLOGÁS (Természetes időközönként lecsukódó szemhéj)
        time_since_blink = now - self.last_blink_time
        if time_since_blink > self.blink_interval:
            blink_progress = (time_since_blink - self.blink_interval) / self.blink_duration
            if blink_progress <= 1.0:
                # Szemhéj lecsukás szimuláció a szemek területén (fej 40-50%-os sávja)
                eye_y_start = int(self.h * 0.42)
                eye_y_end = int(self.h * 0.49)
                eye_x_start = int(self.w * 0.30)
                eye_x_end = int(self.w * 0.70)
                
                eye_roi = frame[eye_y_start:eye_y_end, eye_x_start:eye_x_end]
                # Finom sötétítés/összenyomás a csukott szem illúziójához
                alpha = math.sin(blink_progress * math.pi) * 0.65
                cv2.addWeighted(np.zeros_like(eye_roi), alpha, eye_roi, 1.0 - alpha, 0, eye_roi)
                frame[eye_y_start:eye_y_end, eye_x_start:eye_x_end] = eye_roi
            else:
                self.last_blink_time = now

        # JPEG tömörítés a streamhez
        _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
        return buffer.tobytes()

animator = FaceAnimator(BASE_IMAGE_PATH)

def stream_generator():
    """Folyamatos 30 FPS videóstream biztosítása"""
    while True:
        frame_bytes = animator.generate_frame()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
        time.sleep(0.033)  # ~30 FPS

@app.route('/video_feed')
def video_feed():
    """A Flutter és a böngésző ezt a linket ágyazza be videóként vagy képként"""
    return Response(stream_generator(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/trigger_speech/<int:duration>')
def trigger_speech(duration):
    """Ezt hívja meg a pipeline_orchestrator, amint megszólal a hang"""
    animator.start_speaking(duration)
    return {"status": "SPEAKING_ANIMATION_TRIGGERED", "duration": duration}

if __name__ == '__main__':
    print("[FACE ANIMATOR] Valós idejű arc- és szájanimációs szerver indul: http://127.0.0.1:5006/video_feed")
    app.run(host="127.0.0.1", port=5006, threaded=True)