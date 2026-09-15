# C:\GENEVIEW_CORE\geneview_mobile\layer3_tts.py
import os
import asyncio
import edge_tts

class TextToSpeechModule:
    """3. Hangszintézis Réteg: Neurális beszédgenerálás és időtartam mérés"""
    def __init__(self, voice="hu-HU-NoemiNeural", output_dir="voices/runtime"):
        self.voice = voice
        self.output_dir = os.path.abspath(output_dir)
        os.makedirs(self.output_dir, exist_ok=True)
        print(f"[TTS INITIALIZE] Neurális beszédmodul aktív: {voice}")

    async def _render_voice(self, text: str, target_file: str):
        communicate = edge_tts.Communicate(text, self.voice, rate="+0%", pitch="+0Hz")
        await communicate.save(target_file)

    def synthesize(self, text: str) -> tuple[str, float]:
        output_file = os.path.join(self.output_dir, "geneview_current.mp3")
        asyncio.run(self._render_voice(text, output_file))

        words = len(text.split())
        calculated_duration = max(2.5, round(words / 2.5, 1))

        return output_file, calculated_duration

    def play_on_hardware(self, audio_path: str):
        """Közvetlen megszólaltatás MP3 támogatással"""
        if not os.path.exists(audio_path):
            return
        
        # JAVÍTÁS: A SoundPlayer helyett a WMPlayer COM objektum kell az MP3 háttérbeli lejátszásához
        ps_command = (
            f'$player = New-Object -ComObject WMPlayer.OCX.7; '
            f'$player.URL = "{audio_path}"; '
            f'$player.settings.volume = 100; '
            f'$player.controls.play(); '
            f'Start-Sleep -Seconds 15;'
        )
        os.system(f'powershell -WindowStyle Hidden -Command "{ps_command}"')