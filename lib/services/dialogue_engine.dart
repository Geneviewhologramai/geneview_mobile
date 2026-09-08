import 'package:flutter/foundation.dart';
import '../core/culture/cultural_socialization_engine.dart';
import '../core/vault/sovereign_memory_engine.dart';
import 'neural_cognitive_engine.dart';
import 'prompt_pipeline.dart';
import 'socratic_engine.dart';

class DialogueEngine {
  final SovereignMemoryEngine _memoryVault = SovereignMemoryEngine();
  final SocraticEngine _socraticEngine = SocraticEngine();
  final CulturalSocializationEngine _culturalEngine = CulturalSocializationEngine();
  
  // A magas szintű neurális beszédagy
  final NeuralCognitiveEngine _cognitiveBrain = NeuralCognitiveEngine();

  DialogueEngine() {
    _memoryVault.initStorage();
    _culturalEngine.initializeSocialization();
    debugPrint("[DialogueEngine] Magas szintű generatív beszédagy inicializálva.");
  }

  Future<String> processInput(
    String userInput, {
    UserRole role = UserRole.father,
    String sessionId = "default_session",
  }) async {
    final query = userInput.trim();
    if (query.isEmpty) return "Itt vagyok Uram, figyelek rád.";

    // Helyi mentés a szuverén trezorba
    await _memoryVault.recordInteraction(
      sessionId: sessionId,
      speaker: role == UserRole.father ? "János" : "User",
      content: query,
      valence: 0.2,
    );

    // 1. Gyermek mód szókratészi védelme
    if (role == UserRole.child || _socraticEngine.shouldTriggerSocraticGuidance(query)) {
      final socraticReply = _socraticEngine.generateGuidancePrompt(prompt: query);
      await _recordAiResponse(sessionId, socraticReply);
      return socraticReply;
    }

    // 2. Valódi neurális gondolkodás és válaszalkotás (NINCS TÖBBÉ ISMÉTLÉS!)
    final dynamicAiReply = await _cognitiveBrain.generateAdaptiveResponse(query);

    await _recordAiResponse(sessionId, dynamicAiReply);
    return dynamicAiReply;
  }

  Future<void> _recordAiResponse(String sessionId, String reply) async {
    await _memoryVault.recordInteraction(
      sessionId: sessionId,
      speaker: "Geneviève",
      content: reply,
      valence: 0.5,
    );
  }

  List<Map<String, dynamic>> getRecentHistory({int limit = 5}) {
    return _memoryVault.recallRecentContext(limit: limit);
  }
}