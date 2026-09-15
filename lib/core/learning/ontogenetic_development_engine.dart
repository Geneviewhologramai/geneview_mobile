// lib/core/learning/ontogenetic_development_engine.dart
class OntogeneticDevelopmentEngine {
  int totalInteractionHours = 0;

  void logInteractionTime(int hours) {
    totalInteractionHours += hours;
  }

  String getCognitiveMaturityStage() {
    if (totalInteractionHours < 20) return "Ontogenetikus korai hangolódás";
    if (totalInteractionHours < 100) return "Kibontakozó szimbiózis";
    return "Mély intellektuális érettség";
  }
}