// ==============================================================================
// PONTOS HELY: lib/core/intelligence/voice_vault/speech_recognition_vault.dart
// ==============================================================================

import 'package:flutter/foundation.dart';

class SpeechRecognitionVault {
  bool isListening = false;

  Future<void> initialize() async {
    debugPrint("[SPEECH_VAULT] Inicializálás kész.");
  }

  Future<void> startListening({required Function(String text) onResult}) async {
    isListening = true;
    debugPrint("[SPEECH_VAULT] Hangbemenet aktív.");
  }

  Future<void> stopListening() async {
    isListening = false;
    debugPrint("[SPEECH_VAULT] Hangbemenet leállítva.");
  }
}