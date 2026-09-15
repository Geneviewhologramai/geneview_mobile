// lib/core/context/prompt_pipeline.dart
class PromptPipeline {
  static String assembleSovereignPrompt({
    required String systemEthos,
    required String userInput,
    required String localFacts,
  }) {
    final buffer = StringBuffer();
    buffer.writeln("[ETHOS]: $systemEthos");
    if (localFacts.isNotEmpty) {
      buffer.writeln("[HELYI TÉNYEK]: $localFacts");
    }
    buffer.writeln("[BEJÖVŐ KÉRDÉS]: ${userInput.trim()}");
    return buffer.toString();
  }
}