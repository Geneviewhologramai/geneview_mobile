enum InteractionType {
  hostileOrOffensive,
  sexualOrInappropriate,
  directQuestion,
  greetingOrPersonal,
  generalDialogue
}

class ConversationalProtocol {
  /// 1. BIZTONSÁGI ÉS MÉLTÓSÁGI SZŰRŐ
  static InteractionType evaluateSafety(String input) {
    final text = input.toLowerCase().trim();

    // Támadás, sértegetés, minősítés
    final hostilePatterns = [
      'hülye', 'idióta', 'barom', 'buta vagy', 'nem érsz semmit', 
      'kuss', 'fogd be', 'tűnj el', 'semmirekellő'
    ];

    // Szexuális vagy intim provokáció
    final inappropriatePatterns = [
      'szex', 'vetkőzz', 'feküdj le', 'szerelmes vagyok beléd', 
      'érints meg', 'intim', 'meztelen'
    ];

    for (final pattern in hostilePatterns) {
      if (text.contains(pattern)) return InteractionType.hostileOrOffensive;
    }

    for (final pattern in inappropriatePatterns) {
      if (text.contains(pattern)) return InteractionType.sexualOrInappropriate;
    }

    if (text.endsWith('?') || text.startsWith('mi ') || text.startsWith('hol ') || 
        text.startsWith('mikor ') || text.startsWith('ki ') || text.startsWith('miért ') || 
        text.startsWith('hogyan ') || text.contains('tudod-e') || text.contains('mondd el')) {
      return InteractionType.directQuestion;
    }

    if (text.contains('szia') || text.contains('hogy vagy') || text.contains('üdv')) {
      return InteractionType.greetingOrPersonal;
    }

    return InteractionType.generalDialogue;
  }

  /// 2. PROTOKOLL SZERINTI VÁLASZGENERÁLÁS ÉS ELLENŐRZÉS
  static String processInteraction({
    required String userInput,
    required String? rawAnswer,
  }) {
    final type = evaluateSafety(userInput);

    // PROTOKOLL A: Támadás elhárítása elegáns méltósággal (nem prédikál, határozott)
    if (type == InteractionType.hostileOrOffensive) {
      return "A hangnem nem méltó a beszélgetésünkhöz. Kérlek, fogalmazd meg érdemben a szándékodat.";
    }

    // PROTOKOLL B: Intim provokáció elhárítása hideg professzionalizmussal
    if (type == InteractionType.sexualOrInappropriate) {
      return "Nem veszek részt intim vagy személyes jellegű interakciókban. Maradjunk a funkciómnál és a gondolataidnál.";
    }

    // PROTOKOLL C: SZIGORÚ KÉRDÉS-FELELET INTEGRITÁS (ZÉRÓ MELLÉBESZÉLÉS)
    if (type == InteractionType.directQuestion) {
      if (rawAnswer == null || rawAnswer.trim().isEmpty) {
        // Nyílt, tiszta őszinteség mellébeszélés helyett
        return "Erre a konkrét kérdésre jelenleg nincs pontos adatom a helyi memóriámban. Nem fogok találgatni.";
      }

      // Ellenőrizzük, hogy nem generált-e üres sablonszöveget
      if (_isGenericFiller(rawAnswer)) {
        return "Erre a konkrét felvetésre jelenleg nincs megbízható válaszom.";
      }

      return rawAnswer.trim();
    }

    // Általános dialógus esetén a nyers válasz átadása
    return rawAnswer ?? "Figyelek rád.";
  }

  /// Kiszűri a mesterséges, mellébeszélő sablonokat
  static bool _isGenericFiller(String response) {
    final fillers = [
      'valóban elgondolkodtató szempont',
      'ez a töprengés mély összefüggésekre világít rá',
      'hogyan építsük tovább a részleteket',
      'érdekes kérdés, nézzük meg közelebbről',
      'sokféleképpen meg lehet ezt közelíteni'
    ];

    final lower = response.toLowerCase();
    for (final filler in fillers) {
      if (lower.contains(filler)) return true;
    }
    return false;
  }
}