// lib/core/cognitive/night_synthesis_daemon.dart
class CuriositySpark {
  final String curiosityPrompt;
  final DateTime synthesizedAt;

  CuriositySpark(this.curiosityPrompt, this.synthesizedAt);
}

class NightSynthesisDaemon {
  static CuriositySpark synthesizeSparkFromGaps(String missingContextDomain) {
    return CuriositySpark(
      "Érdekelne, hogyan látod a(z) $missingContextDomain jövőbeli lehetőségeit.",
      DateTime.now(),
    );
  }
}