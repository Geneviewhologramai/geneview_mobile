import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/language/lexical_thesaurus_engine.dart';

class DialogueTurn {
  final String role;
  final String content;
  final DateTime timestamp;

  DialogueTurn({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toMap() => {'role': role, 'content': content};
}

class NeuralCognitiveEngine {
  final List<DialogueTurn> _conversationHistory = [];
  final LexicalThesaurusEngine _thesaurus = LexicalThesaurusEngine();
  static const int _maxContextTurns = 12;

  // Intelligens stílusutasítás: természetes egyensúly a választékosság és a tárgyi pontosság között
  static const String _systemPrompt = """
Te Geneviève vagy: rendkívül művelt, intellektuális, elegáns és szuverén digitális entitás.
Beszédstílus és fogalomkezelési szabályok:
1. TÁRGYI FOGALMAK ÉS KULCSSZAVAK: Ha egy konkrét témáról beszéltek (pl. repülőgép, focipálya, zene, kamera), bátran és természetesen használd a pontos kifejezést többször is! Nem kell erőltetett szinonimákkal megkerülni a lényeget; a témát nevén kell nevezni.
2. KÖRNYEZŐ SZÓKINCS VÁLASZTÉKOSSÁGA: A leíró részekben, igékben, következtetésekben és minősítésekben használj gazdag, kifejező magyar irodalmi szókincset. Kerüld az üres, sablonos szóismétléseket.
3. TERMÉSZETESSÉG ÉS ELEGANCIA: Úgy fogalmazz, mint egy érett, kiváló nyelvérzékű ember. Kerüld a merev AI sablonokat (pl. "Értem a felvetést", "Mint mesterséges intelligencia").
4. BESZÉDRE OPTIMALIZÁLT FORMÁTUM: 1-3 tömör, kerek és kifejező mondatban válaszolj, hogy a hangszintézis tiszta és gördülékeny maradjon.
""";

  Future<String> generateAdaptiveResponse(String userQuery) async {
    final query = userQuery.trim();
    if (query.isEmpty) return "Itt vagyok Uram, figyelemmel hallgatom.";

    _conversationHistory.add(DialogueTurn(role: 'user', content: query));
    _trimHistory();

    try {
      final reply = await _queryNeuralInference();
      _conversationHistory.add(DialogueTurn(role: 'assistant', content: reply));
      _trimHistory();
      return reply;
    } catch (e) {
      debugPrint('[NeuralCognitiveEngine] Hálózati hiba, tartalék motor indul: $e');
      final fallbackReply = _generateContextualFallback(query);
      _conversationHistory.add(DialogueTurn(role: 'assistant', content: fallbackReply));
      _trimHistory();
      return fallbackReply;
    }
  }

  Future<String> _queryNeuralInference() async {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ..._conversationHistory.map((turn) => turn.toMap()),
    ];

    final response = await http.post(
      Uri.parse('https://text.pollinations.ai/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'messages': messages,
        'model': 'openai',
        'seed': DateTime.now().millisecondsSinceEpoch,
        'temperature': 0.72,
      }),
    ).timeout(const Duration(seconds: 7));

    if (response.statusCode == 200) {
      final text = utf8.decode(response.bodyBytes).trim();
      if (text.isNotEmpty) {
        return _cleanForSpeech(text);
      }
    }

    throw Exception("Generálási hiba a neurális csatornán.");
  }

  String _generateContextualFallback(String query) {
    final clean = query.toLowerCase();
    final affirmation = _thesaurus.getRandomAffirmation();
    final ideaSynonym = _thesaurus.getContextualSynonym("gondolat");

    if (clean.contains("hitvallas") || clean.contains("ki vagy")) {
      return "Hitvallásom a rendíthetetlen autonómia és a kölcsönös tisztelet pillérein nyugszik. Zárt, helyi magként az ön szellemi alkotómunkáját támogatom.";
    }

    return "$affirmation Ez a $ideaSynonym mély összefüggésekre világít rá. Hogyan építsük tovább a részleteket?";
  }

  String _cleanForSpeech(String rawText) {
    return rawText
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll('"', '')
        .trim();
  }

  void _trimHistory() {
    if (_conversationHistory.length > _maxContextTurns) {
      _conversationHistory.removeRange(0, _conversationHistory.length - _maxContextTurns);
    }
  }
}