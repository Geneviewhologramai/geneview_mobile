Future<String> thinkAndRespond(String userInput) async {
  final cleanInput = userInput.trim();
  if (cleanInput.isEmpty) return "Hallgatlak, figyelek rád.";

  // 1. Biztonsági és formai ellenőrzés
  final safety = ConversationalProtocol.evaluateSafety(cleanInput);
  if (safety == InteractionType.hostileOrOffensive || 
      safety == InteractionType.sexualOrInappropriate) {
    return ConversationalProtocol.processInteraction(
      userInput: cleanInput, 
      rawAnswer: null
    );
  }

  // 2. Személyes / udvariassági kérdések
  if (safety == InteractionType.greetingOrPersonal) {
    return _generateSophisticatedStateResponse(cleanInput.toLowerCase());
  }

  // 3. Ténybeli kérdés megválaszolása
  String? rawAnswer;
  try {
    rawAnswer = await _queryKnowledgeBase(cleanInput);
  } catch (_) {
    rawAnswer = null;
  }

  // 4. Protokoll kényszerítése (ha üres vagy blabla lenne, a protokoll őszintén leállítja)
  return ConversationalProtocol.processInteraction(
    userInput: cleanInput,
    rawAnswer: rawAnswer,
  );
}