import 'package:flutter/foundation.dart';

/// Socratic Engine a kérdező, rávezető gyermek- és alkotói interakcióhoz.
/// Dart / Flutter port: lib/services/socratic_engine.dart
class SocraticEngine {
  SocraticEngine() {
    debugPrint("[SocraticEngine] SocraticEngine inicializálva.");
  }

  /// Közvetlen kész válasz helyett szokratikus visszakérdezéssel és rávezetéssel válaszol.
  String generateGuidancePrompt({
    required String prompt,
    String userId = "default_user",
    String guardReason = "",
  }) {
    return "Szívesen segítek megérteni a feladatot, de a megoldást neked kell kitalálnod! "
        "Mondd el, meddig jutottál el a(z) '$prompt' kérdésben, vagy mi a legnehezebb rész benne?";
  }

  /// Ellenőrzi, hogy a kérdés szokratikus pedagógiai rávezetést igényel-e
  bool shouldTriggerSocraticGuidance(String input) {
    final lower = input.toLowerCase();
    final homeworkKeywords = [
      'oldd meg helyettem',
      'írd meg a házimat',
      'mennyi az eredmény',
      'mondd meg a választ',
      'csináld meg nekem',
    ];
    return homeworkKeywords.any((kw) => lower.contains(kw));
  }
}