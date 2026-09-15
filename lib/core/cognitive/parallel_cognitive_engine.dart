// lib/core/cognitive/parallel_cognitive_engine.dart
class ParallelCognitiveEngine {
  static String selectMostRefinedThought(List<String> candidateReplies) {
    if (candidateReplies.isEmpty) return "Hallgatlak.";
    candidateReplies.sort((a, b) => b.length.compareTo(a.length));
    return candidateReplies.first;
  }
}