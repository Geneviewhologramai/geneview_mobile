import os
import sys
import json
import requests
import threading
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False
CORS(app, resources={r"/*": {"origins": "*"}})

# Konfiguráció
OLLAMA_ENDPOINT = "http://127.0.0.1:11434/api/generate"
OLLAMA_MODEL = "llama3:latest"  # vagy mistral, gemma

# Rendszerprompt (A modell személyisége és intellektuális viselkedése)
SYSTEM_PROMPT = """
Te GENEVIEW vagy, egy intellektuális, önálló, empatikus és mélyen gondolkodó mesterséges intelligencia asszisztens.
Válaszaid legyenek természetesek, emberiek, összeszedettek és intelligensek. 
Kerüld a sablonos, merev vagy gépies formulákat. 
Kommunikálj úgy, mint egy tapasztalt, művelt és figyelmes beszélgetőtárs.
Mindig a felhasználó által használt nyelven (alapértelmezetten magyarul) válaszolj.
"""

class ConversationMemory:
    """Rövid távú memóriapuffer a kontextus megőrzéséhez"""
    def __init__(self, max_turns=6):
        self.history = []
        self.max_turns = max_turns
        self.lock = threading.Lock()

    def add_interaction(self, user_msg, ai_msg):
        with self.lock:
            self.history.append({"user": user_msg, "geneview": ai_msg})
            if len(self.history) > self.max_turns:
                self.history.pop(0)

    def get_context_prompt(self, current_query):
        with self.lock:
            prompt = SYSTEM_PROMPT.strip() + "\n\n"
            for turn in self.history:
                prompt += f"Felhasználó: {turn['user']}\nGENEVIEW: {turn['geneview']}\n"
            prompt += f"Felhasználó: {current_query}\nGENEVIEW:"
            return prompt

memory = ConversationMemory()

def query_llm_brain(prompt_text):
    """Lekérdezés a lokális nyílt forráskódú LLM felé (Ollama)"""
    try:
        payload = {
            "model": OLLAMA_MODEL,
            "prompt": prompt_text,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9
            }
        }
        resp = requests.post(OLLAMA_ENDPOINT, json=payload, timeout=30)
        if resp.status_code == 200:
            return resp.json().get("response", "").strip()
        else:
            return "Gondolataim összegzése során kisebb hálózati késleltetés lépett fel."
    except requests.exceptions.RequestException:
        # Fallback intelligens válasz, ha a helyi LLM motor nincs elindítva
        return "Értem a felvetésedet. A kognitív hálózat jelenleg helyi üzemmódban fut, a gondolati folyamatok tisztázása folyamatban van."

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "COGNITIVE_ACTIVE", "model": OLLAMA_MODEL}), 200

@app.route('/think_and_speak', methods=['POST'])
def think_and_speak():
    data = request.get_json(force=True, silent=True) or {}
    user_query = data.get("query", "").strip()

    if not user_query:
        return jsonify({"answer": "Figyelek rád, miről szeretnél beszélni?", "duration": 3}), 200

    # 1. Teljes prompt összeállítása a kontextussal
    full_prompt = memory.get_context_prompt(user_query)

    # 2. Dinamikus válasz generálása az LLM által
    ai_answer = query_llm_brain(full_prompt)

    # 3. Interakció elmentése a memóriába
    memory.add_interaction(user_query, ai_answer)

    # 4. Becsült beszédidő kalkulációja (szavak száma alapján az animáció időzítéséhez)
    word_count = len(ai_answer.split())
    estimated_duration = max(3, int(word_count / 2.5))

    return jsonify({
        "answer": ai_answer,
        "duration": estimated_duration,
        "status": "DYNAMIC_RESONANCE",
        "audio_url": None  # Ide csatlakoztatható a dinamikus TTS stream
    }), 200

if __name__ == "__main__":
    print("[GENEVIEW COGNITIVE CORE] Kognitív nyelvi motor elindult az 5005-ös porton...")
    app.run(host="127.0.0.1", port=5005, debug=False)