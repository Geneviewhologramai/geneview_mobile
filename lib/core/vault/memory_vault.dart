import 'package:flutter/foundation.dart';

class MemoryVault {
  static final MemoryVault _instance = MemoryVault._internal();
  factory MemoryVault() => _instance;
  MemoryVault._internal();

  final List<Map<String, dynamic>> _episodes = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('[MemoryVault] Helyi széf inicializálva (Web/In-Memory mód).');
  }

  Future<void> recordInteraction({
    required String prompt,
    required String response,
    required double valence,
    required double arousal,
  }) async {
    _episodes.add({
      'timestamp': DateTime.now().toIso8601String(),
      'prompt': prompt,
      'response': response,
      'valence': valence,
      'arousal': arousal,
    });
    debugPrint('[MemoryVault] Interakció rögzítve: $prompt');
  }

  List<Map<String, dynamic>> get episodes => List.unmodifiable(_episodes);
}