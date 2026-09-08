import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class VoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  dynamic _recognition;
  bool _isListening = false;
  List<dynamic> _availableVoices = [];

  // A helyi belső Piper TTS motor címe (ha fut a helyi audio pipeline)
  final String _localTtsEndpoint = 'http://127.0.0.1:5000/tts';

  VoidCallback? onSpeechStarted;
  VoidCallback? onSpeechFinished;
  Function(String text)? onTranscriptReceived;

  bool get isListening => _isListening;

  Future<void> init() async {
    _loadVoices();
    _initSpeechRecognition();

    _audioPlayer.onPlayerComplete.listen((_) {
      onSpeechFinished?.call();
    });
  }

  void _loadVoices() {
    try {
      final synth = html.window.speechSynthesis;
      if (synth != null) {
        _availableVoices = synth.getVoices();
        synth.addEventListener('voiceschanged', (html.Event _) {
          final s = html.window.speechSynthesis;
          if (s != null) {
            _availableVoices = s.getVoices();
          }
        });
      }
    } catch (_) {}
  }

  void _initSpeechRecognition() {
    try {
      final dynamic windowObj = html.window;
      final speechClass =
          windowObj['webkitSpeechRecognition'] ?? windowObj['SpeechRecognition'];

      if (speechClass != null) {
        _recognition = speechClass.newInstance([]);
        _recognition.continuous = false;
        _recognition.interimResults = false;
        _recognition.lang = 'hu-HU';

        _recognition.onstart = (_) => _isListening = true;
        _recognition.onend = (_) => _isListening = false;
        _recognition.onerror = (_) => _isListening = false;

        _recognition.onresult = (event) {
          try {
            final results = event.results;
            if (results != null && results.length > 0) {
              final transcript = results[0][0].transcript.toString().trim();
              if (transcript.isNotEmpty) {
                onTranscriptReceived?.call(transcript);
              }
            }
          } catch (_) {}
        };
      }
    } catch (_) {}
  }

  void startListening() {
    try {
      _recognition?.start();
      _isListening = true;
    } catch (_) {
      _isListening = false;
    }
  }

  void stopListening() {
    try {
      _recognition?.stop();
    } catch (_) {}
    _isListening = false;
  }

  Future<void> speak(String text, {double rate = 0.90, double pitch = 1.02}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    await stop();
    onSpeechStarted?.call();

    // 1. Elsődleges kísérlet: Lokális Berta TTS meghívása
    try {
      final response = await http.post(
        Uri.parse(_localTtsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: '{"text": "${cleanText.replaceAll('"', '\\"')}", "model": "hu_HU-berta-medium"}',
      ).timeout(const Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        await _audioPlayer.play(BytesSource(response.bodyBytes));
        return;
      }
    } catch (_) {
      // Ha a lokális backend Piper nem elérhető, tartalék módba kapcsol
    }

    // 2. Tartalék kísérlet: Böngésző natív beszédszintetizátora
    _fallbackWebSpeech(cleanText, rate: rate, pitch: pitch);
  }

  void _fallbackWebSpeech(String cleanText, {required double rate, required double pitch}) {
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) {
        onSpeechFinished?.call();
        return;
      }

      final utterance = html.SpeechSynthesisUtterance(cleanText);
      utterance.lang = 'hu-HU';
      utterance.rate = rate;
      utterance.pitch = pitch;

      if (_availableVoices.isEmpty) {
        _availableVoices = synth.getVoices();
      }

      dynamic bestVoice;
      for (final v in _availableVoices) {
        final name = (v.name ?? '').toString().toLowerCase();
        final lang = (v.lang ?? '').toString().toLowerCase();
        if (name.contains('enhanced') || name.contains('premium') || name.contains('berta')) {
          if (lang.startsWith('hu') || name.contains('mariska')) {
            bestVoice = v;
            break;
          }
        }
      }

      if (bestVoice != null) {
        utterance.voice = bestVoice;
      }

      bool hasEnded = false;
      Timer? safetyTimer;

      void endSpeech() {
        if (!hasEnded) {
          hasEnded = true;
          safetyTimer?.cancel();
          onSpeechFinished?.call();
        }
      }

      utterance.onEnd.listen((_) => endSpeech());
      utterance.onError.listen((_) => endSpeech());

      final calculatedSeconds = (cleanText.length / 9).clamp(4.0, 25.0).toInt();
      safetyTimer = Timer(Duration(seconds: calculatedSeconds), () => endSpeech());

      synth.speak(utterance);
    } catch (_) {
      onSpeechFinished?.call();
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
    stopListening();
    onSpeechFinished?.call();
  }
}