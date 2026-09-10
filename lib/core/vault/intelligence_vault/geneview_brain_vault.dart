import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geneview_mobile/core/contracts/i_brain_vault.dart';

class GeneviewBrainVault implements IBrainVault {
  final String _serverUrl = 'http://127.0.0.1:5005/think_and_speak';

  @override
  Future<String> processThought(String input) async {
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': input}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? 'Nem érkezett válasz.';
      } else {
        return 'Szerver válaszadási hiba: ${response.statusCode}';
      }
    } catch (e) {
      return 'Nem sikerült elérni a Geneview Python agyat: $e';
    }
  }

  Future<void> resetState() async {
    // Memória vagy belső állapot alaphelyzetbe állítása
  }
}