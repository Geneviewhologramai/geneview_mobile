import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/contracts/i_brain_vault.dart';
import '../../core/intelligence/conversational_protocol.dart';
import 'geneview_universe_state.dart';

class GeneviewBrainVault implements IBrainVault {
  final GeneviewUniverseState universe;

  GeneviewBrainVault({required this.universe});

  @override
  Future<String> processThought(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return "Hallgatlak, figyelek rád.";

    // 1. Biztonsági és formai ellenőrzés
    final safety = ConversationalProtocol.evaluateSafety(cleanInput);
    if (safety == InteractionType.hostileOrOffensive ||
        safety == InteractionType.sexualOrInappropriate) {
      return ConversationalProtocol.processInteraction(
        userInput: cleanInput,
        rawAnswer: null,
      );
    }

    // 2. Személyes / Érzelmi állapot megválaszolása
    if (safety == InteractionType.greetingOrPersonal) {
      return _evaluatePersonalState(cleanInput);
    }

    // 3. Tudáslekérdezés és Új Csillag Születése (New Star Discovered)
    String? rawAnswer;
    try {
      rawAnswer = await _fetchExternalKnowledge(cleanInput);
      if (rawAnswer != null && rawAnswer.isNotEmpty) {
        // Térbeli lehorgonyzás a gömbben
        universe.discoverStar(
          label: cleanInput.length > 20 ? cleanInput.substring(0, 20) : cleanInput,
          domain: 'TUDÁSTÁR',
          x: (cleanInput.hashCode % 10).toDouble(),
          y: ((cleanInput.length * 7) % 10).toDouble(),
          z: 2.0,
        );
      }
    } catch (_) {
      rawAnswer = null;
    }

    // 4. Szigorú protokoll-kényszerítés
    return ConversationalProtocol.processInteraction(
      userInput: cleanInput,
      rawAnswer: rawAnswer,
    );
  }

  String _evaluatePersonalState(String input) {
    final nearest = universe.getNearestToCore();
    final anchorNames = nearest.map((s) => s.label).join(', ');
    return "A belső folyamataim rendezettek, a mag stabil. Jelenleg a legközelebbi horgonypontjaim: $anchorNames. Miről szeretnél beszélni?";
  }

  Future<String?> _fetchExternalKnowledge(String query) async {
    final searchUri = Uri.parse(
      'https://hu.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro=1&explaintext=1&titles=${Uri.encodeComponent(query)}&redirects=1',
    );
    final response = await http.get(searchUri).timeout(const Duration(seconds: 3));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final Map<String, dynamic>? pages = data['query']?['pages'];
      if (pages != null && pages.isNotEmpty) {
        final firstKey = pages.keys.first;
        if (firstKey != "-1") {
          final String extract = pages[firstKey]['extract'] ?? '';
          if (extract.isNotEmpty) {
            final sentences = extract.split(RegExp(r'(?<=[.!?])\s+'));
            return sentences.take(2).join(' ').trim();
          }
        }
      }
    }
    return null;
  }
}