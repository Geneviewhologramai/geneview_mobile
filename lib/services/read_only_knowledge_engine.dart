import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ReadOnlyKnowledgeEngine {
  static const String _wikiApiUrl = 'https://hu.wikipedia.org/w/api.php';

  Future<String?> fetchKnowledge(String query) async {
    try {
      final topic = _extractSearchTopic(query);
      if (topic.isEmpty) return null;

      final uri = Uri.parse(
        '$_wikiApiUrl?action=query&format=json&prop=extracts&exintro=true&explaintext=true&titles=${Uri.encodeComponent(topic)}&origin=*',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;

        if (pages != null && pages.isNotEmpty) {
          final firstKey = pages.keys.first;
          if (firstKey != '-1') {
            final String extract = pages[firstKey]['extract'] ?? '';
            if (extract.trim().isNotEmpty) {
              return _summarize(extract);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[KnowledgeEngine] Lekérési hiba: $e');
    }
    return null;
  }

  String _extractSearchTopic(String input) {
    return input
        .replaceAll(RegExp(r'(mi az a|mi az az|ki az a|ki volt|mit jelent a|mondd el|tudsz rola|meselj a)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'[?.,!]'), '')
        .trim();
  }

  String _summarize(String text) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.isNotEmpty) {
      final res = sentences.take(2).join(' ');
      return res.length > 280 ? '${res.substring(0, 277)}...' : res;
    }
    return text;
  }
}