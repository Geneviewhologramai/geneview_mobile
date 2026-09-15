import time
import datetime
import threading

class GeneviewInternalClock:
    """
    Geneview autonóm belső kronológiai rendszere.
    Folyamatosan számon tartja a valós időt, dátumot, napokat és napszakokat.
    """
    NAPOK = ["hétfő", "kedd", "szerda", "csütörtök", "péntek", "szombat", "vasárnap"]
    HONAPOK = [
        "január", "február", "március", "április", "május", "június",
        "július", "augusztus", "szeptember", "október", "november", "december"
    ]

    def __init__(self):
        self._running = True
        self._current_time = datetime.datetime.now()
        self._lock = threading.Lock()
        
        # Belső háttérszál indítása a folyamatos ketyegéshez
        self._ticker_thread = threading.Thread(target=self._tick_loop, daemon=True)
        self._ticker_thread.start()

    def _tick_loop(self):
        """Másodpercenként frissülő belső óra."""
        while self._running:
            with self._lock:
                self._current_time = datetime.datetime.now()
            time.sleep(1)

    def get_datetime(self) -> datetime.datetime:
        with self._lock:
            return self._current_time

    def get_greeting(self) -> str:
        """Napszaknak megfelelő megszólítás."""
        hour = self.get_datetime().hour
        if 5 <= hour < 10:
            return "Jó reggelt"
        elif 10 <= hour < 18:
            return "Kellemes napot"
        elif 18 <= hour < 22:
            return "Jó estét"
        else:
            return "Szép jó éjszakát"

    def get_full_chronos_status(self) -> str:
        """Részletes kronológiai állapot az AI gondolkodásához."""
        now = self.get_datetime()
        nap_neve = self.NAPOK[now.weekday()]
        honap_neve = self.HONAPOK[now.month - 1]
        
        return (
            f"Év: {now.year}, Hónap: {honap_neve} ({now.month:02d}), "
            f"Nap: {now.day:02d}., A hét napja: {nap_neve}. "
            f"Pontos idő: {now.strftime('%H:%M:%S')}. "
            f"Aktuális napszak: {self.get_greeting()}."
        )

    def answer_time_query(self, query: str) -> str:
        """Közvetlen, szabatos válasz bármilyen időre/dátumra irányuló kérdésre."""
        now = self.get_datetime()
        nap_neve = self.NAPOK[now.weekday()]
        honap_neve = self.HONAPOK[now.month - 1]
        q = query.lower()

        if any(w in q for w in ["hány óra", "mennyi az idő", "pontos idő"]):
            return f"{self.get_greeting()}! A belső órám szerint a pontos idő {now.strftime('%H:%M')}."

        if any(w in q for w in ["milyen nap", "milyen nap van ma"]):
            return f"Ma {now.year}. {honap_neve} {now.day}., {nap_neve} van."

        if any(w in q for w in ["milyen év", "melyik év"]):
            return f"Jelenleg a {now.year}-es évet írjuk."

        if any(w in q for w in ["milyen hónap", "melyik hónap"]):
            return f"Most {honap_neve} hónap van."

        return (
            f"A belső kronológiai magom szerint ma {now.year}. {honap_neve} {now.day}., "
            f"{nap_neve} van, a pontos idő pedig {now.strftime('%H:%M')}."
        )

# Egyetlen globális órapéldány
chronos = GeneviewInternalClock()