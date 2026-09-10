import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognitionVault {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    if (!_isAvailable) {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('STT Hiba: $val'),
        onStatus: (val) => debugPrint('STT Állapot: $val'),
      );
    }
    return _isAvailable;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    final available = await initialize();
    if (!available) return;

    await _speech.listen(
      localeId: 'hu_HU', // Magyar nyelvű felismerés
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
        if (result.finalResult) {
          onDone();
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}