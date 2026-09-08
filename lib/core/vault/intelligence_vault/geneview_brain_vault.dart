import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/contracts/i_brain_vault.dart';
import '../../core/intelligence/conversational_protocol.dart';

class GeneviewBrainVault implements IBrainVault {
  @override
  Future<String> processThought(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return "Hallgatlak, figyelek rád.";

    // 1. Biztonsági protokoll ellenőrzése
    final safety = ConversationalProtocol.evaluateSafety(cleanInput);
    if (safety == InteractionType.hostileOrOffensive ||
        safety == InteractionType.sexualOrInappropriate) {
      return ConversationalProtocol.processInteraction(
        userInput: cleanInput,
        rawAnswer: null,
      );
    }

    // 2. Személyes / állapottal kapcsolatos kérdés
    if (safety == InteractionType.greetingOrPersonal) {
      return _generateStateResponse(cleanInput.toLowerCase());
    }

    // 3. Tényalapú tudáslekérdezés (Online / Offline adat)
    String? rawAnswer;
    try {
      rawAnswer = await _fetchKnowledge(cleanInput);
    } catch (_) {
      rawAnswer = null;
    }

    // 4. Protokoll kényszerítése (nincs sablonos félrebeszélés)
    return ConversationalProtocol.processInteraction(
      userInput: cleanInput,
      rawAnswer: rawAnswer,
    );
  }

  String _generateStateResponse(String text) {
    if (text.contains("hogy vagy") || text.contains("hogy érzed")) {
      return "Köszönöm, a belső folyamataim rendezettek és kiegyensúlyozottak. Készen állok arra, amin éppen gondolkodsz.";
    }
    return "Üdvözöllek. Milyen összefüggést vizsgálunk meg ma?";
  }

  Future<String?> _fetchKnowledge(String query) async {
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