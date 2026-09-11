// ==============================================================================
// PONTOS HELY: lib/services/voice_service.dart
// ==============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

class VoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final bool _isListening = false;
  final List<dynamic> _availableVoices = [];

  final String _localTtsEndpoint = 'http://127.0.0.1:5005/think_and_speak';

  bool get isListening => _isListening;
  List<dynamic> get availableVoices => _availableVoices;

  Future<void> initVoice() async {
    debugPrint("[VOICE_SERVICE] Inicializálás kész.");
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await http.post(
        Uri.parse(_localTtsEndpoint),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: '{"query": "$text"}',
      );
    } catch (e) {
      debugPrint("[VOICE_SERVICE HIBA] $e");
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}