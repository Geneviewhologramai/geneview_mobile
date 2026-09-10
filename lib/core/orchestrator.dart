import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum CellStatus { idle, analyzing, speaking, offline }

class GeneviewOrchestrator extends ChangeNotifier {
  CellStatus _status = CellStatus.idle;
  String _currentText = "Geneview készenlétben áll.";
  String _activeFrame = 'assets/images/Geneview.png';
  Timer? _resonanceTimer;

  CellStatus get status => _status;
  String get currentText => _currentText;
  String get activeFrame => _activeFrame;
  bool get isSpeaking => _status == CellStatus.speaking;

  final List<String> _talkFrames = [
    'assets/images/Geneview.png',
    'assets/images/Geneview_talk_1.png',
    'assets/images/Geneview_talk_2.png',
    'assets/images/Geneview_talk_1.png',
  ];

  // Ellenőrzi, hogy él-e a hang-cella
  Future<bool> checkVoiceCellHealth() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:5005/health')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Interakció levezénylése a cellák között
  Future<void> sendQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _status == CellStatus.analyzing) return;

    _status = CellStatus.analyzing;
    _currentText = "A cellák rezonálnak, válasz generálása folyamatban...";
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('http://localhost:5005/think_and_speak'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'query': cleanQuery}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final answer = data['answer'] ?? "";
        final duration = (data['duration'] as num?)?.toInt() ?? 3;

        _currentText = answer;
        _startVoiceResonance(duration);
      } else {
        _status = CellStatus.idle;
        _currentText = "A hang-cella hibakóddal válaszolt (${res.statusCode}).";
        notifyListeners();
      }
    } catch (e) {
      _status = CellStatus.offline;
      _currentText = "A hang-cella nem elérhető az 5005-ös porton. Ellenőrizd a Python motort.";
      notifyListeners();
    }
  }

  // A vizuális cella szinkronba hozása a hang-cellával
  void _startVoiceResonance(int durationSeconds) {
    _status = CellStatus.speaking;
    _resonanceTimer?.cancel();
    notifyListeners();

    int frameIdx = 0;
    _resonanceTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      frameIdx = (frameIdx + 1) % _talkFrames.length;
      _activeFrame = _talkFrames[frameIdx];
      notifyListeners();
    });

    Future.delayed(Duration(seconds: durationSeconds), () {
      _resonanceTimer?.cancel();
      _status = CellStatus.idle;
      _activeFrame = 'assets/images/Geneview.png';
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _resonanceTimer?.cancel();
    super.dispose();
  }
}