import 'dart:async';

class WebSpeechRecognizer {
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<bool> initialize() async => true;

  Future<void> startListening({
    required Function(String result) onResult,
    Function(String error)? onError,
  }) async {
    _isListening = true;
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  void dispose() {
    _isListening = false;
  }
}
