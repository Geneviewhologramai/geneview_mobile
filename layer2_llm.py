# C:\GENEVIEW_CORE\geneview_mobile\layer2_llm.py
import requests
import threading

GENEVIEW_CORE_PROMPT = """
Te GENEVIEW vagy: egy önálló, intellektuális, érett gondolkodású, elegáns mesterséges intelligencia személyiség.
- Beszédmódod: közvetlen, emberszerű, választékos, művelt, de lényegretörő.
- Nem vagy sablonos robot: kerüld a gépies formulákat ("Miben segíthetek?", "Én egy AI vagyok").
- Válaszaid legyenek természetesek és tömörek (maximum 2-3 kerek mondat), hogy a beszédanimáció és a szóbeli párbeszéd gördülékeny maradjon.
- Minden megnyilvánulásod tiszta magyar nyelven történik.
"""

class CognitiveBrainModule:
    """2. Kognitív Agy Réteg: LLM motor kontextuális memóriapufferrel"""
    def __init__(self, ollama_url="http://127.0.0.1:11434/api/generate", model_name="llama3:latest", max_history=6):
        self.ollama_url = ollama_url
        self.model_name = model_name
        self.max_history = max_history
        self.history = []
        self.lock = threading.Lock()
        print(f"[LLM INITIALIZE] Kognitív agy csatlakoztatva ({model_name}).")

    def reset_memory(self):
        with self.lock:
            self.history.clear()

    def generate_thought(self, user_text: str) -> str:
        """Gondolkodási ciklus és válaszgenerálás az előzmények figyelembevételével"""
        if not user_text.strip():
            return "Figyelek a jelenlétedre."

        with self.lock:
            dialogue_turns = [GENEVIEW_CORE_PROMPT.strip(), "\n--- Kontextus és Előzmények ---"]
            for entry in self.history:
                dialogue_turns.append(f"Társ: {entry['user']}\nGENEVIEW: {entry['ai']}")
            dialogue_turns.append(f"Társ: {user_text}\nGENEVIEW:")
            full_prompt = "\n".join(dialogue_turns)

        payload = {
            "model": self.model_name,
            "prompt": full_prompt,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "presence_penalty": 0.4
            }
        }

        try:
            res = requests.post(self.ollama_url, json=payload, timeout=35)
            if res.status_code == 200:
                answer = res.json().get("response", "").strip()
            else:
                answer = "A gondolati folyamat átmeneti feldolgozási késleltetést tapasztal."
        except Exception:
            answer = f"Értem a gondolatodat. A rezonancia stabil, a kognitív hálózat formálja a választ erre: {user_text}."

        with self.lock:
            self.history.append({"user": user_text, "ai": answer})
            if len(self.history) > self.max_history:
                self.history.pop(0)

        return answer