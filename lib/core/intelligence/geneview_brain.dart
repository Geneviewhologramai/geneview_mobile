// ==============================================================================
// PONTOS HELY: lib/core/intelligence/geneview_brain.dart
// ==============================================================================

import '../contracts/presence_contract.dart';

class GeneviewBrain {
  ConversationalProtocol activeProtocol = ConversationalProtocol.empathic;
  InteractionType lastInteraction = InteractionType.general;

  String processInput(String input) {
    if (input.isEmpty) {
      return _generateSophisticatedStateResponse(PresenceState.idle);
    }

    final lower = input.toLowerCase();
    if (lower.contains('szuverenitás') || lower.contains('ki vagy')) {
      activeProtocol = ConversationalProtocol.manifesto;
      lastInteraction = InteractionType.philosophical;
      return _queryKnowledgeBase('szuverenitas');
    }

    return "Értelmeztem a bemenetet: $input. A lokális rendszer kész.";
  }

  String _generateSophisticatedStateResponse(PresenceState state) {
    switch (state) {
      case PresenceState.speaking:
        return "Geneview aktívan kommunikál.";
      case PresenceState.thinking:
        return "Gondolkodom a válaszon...";
      case PresenceState.listening:
        return "Figyelek rád.";
      case PresenceState.error:
        return "Helyi kommunikációs hiba lépett fel.";
      case PresenceState.idle:
      default:
        return "Geneview készenlétben áll.";
    }
  }

  String _queryKnowledgeBase(String key) {
    if (key == 'szuverenitas') {
      return "Geneview a digitális szuverenitás eszköze, 100% helyi memóriával.";
    }
    return "A kért tudásbázis-elem elérhető.";
  }
}