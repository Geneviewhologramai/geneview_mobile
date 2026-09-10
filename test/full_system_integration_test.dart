import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:geneview_mobile/presentation/hologram_display_screen.dart';

void main() {
  group('GENEVIEW Teljes Rendszer & Hang-Integrációs Audit', () {

    // 1. AUDIT: 5005-ös port és TTS motor elérhetősége
    test('AUDIT 1: Python TTS szerver kapcsolat és válaszkészség (5005)', () async {
      final url = Uri.parse('http://127.0.0.1:5005/think_and_speak');
      
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'query': 'ki vagy te'}),
        ).timeout(const Duration(seconds: 4));

        expect(response.statusCode, 200, 
            reason: 'A szerver elérhető, de nem 200 OK választ adott (Status: ${response.statusCode})');

        final data = jsonDecode(utf8.decode(response.bodyBytes));
        expect(data.containsKey('answer'), isTrue, 
            reason: 'A szerver válasza nem tartalmaz "answer" mezőt');
        expect(data['answer'].toString().isNotEmpty, isTrue, 
            reason: 'A szerver üres választ adott vissza');

      } on SocketException catch (_) {
        fail('KRITIKUS HIBA: A Python szerver NEM FUT az 5005-ös porton! Indítsd el a python_tts_uploader_server.py fájlt.');
      } on HttpException catch (e) {
        fail('Hálózati protokoll hiba: $e');
      }
    });

    // 2. AUDIT: Belépési pont és komponens integritás
    test('AUDIT 2: lib/main.dart és HologramDisplayScreen bekötése', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);

      final content = mainFile.readAsStringSync();
      expect(content.contains('presentation/hologram_display_screen.dart'), isTrue,
          reason: 'A main.dart nem importálja a vetítő képernyőt.');
      expect(content.contains('HologramDisplayScreen('), isTrue,
          reason: 'A HologramDisplayScreen nincs beágyazva a widget fába.');
    });

    // 3. AUDIT: Vizuális architektúra és képkocka-kompatibilitás
    testWidgets('AUDIT 3: Vizuális keretrendszer és vetítési módok', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HologramDisplayScreen(
              activeFrame: 'assets/images/Geneview.png',
              isSpeaking: true,
            ),
          ),
        ),
      );

      // Alapértelmezett PYRAMID 4X mód ellenőrzése
      expect(find.byType(Image), findsNWidgets(4),
          reason: 'Piramis módban a 4 darab elforgatott képkockának meg kell jelennie.');

      // Standard mód váltás
      await tester.tap(find.text('STANDARD'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget,
          reason: 'Standard módban 1 főképnek kell megjelennie.');
    });
  });
}