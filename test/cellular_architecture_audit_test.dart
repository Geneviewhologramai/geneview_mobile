import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geneview_mobile/core/orchestrator.dart';
import 'package:geneview_mobile/presentation/hologram_display_screen.dart';
import 'package:http/http.dart' as http;

void main() {
  group('GENEVIEW Sejtes Architektúra & Rezonancia Audit', () {

    // 1. CELLA AUDIT: A Hang-Cella (Voice Nexus) önálló membránjának vizsgálata
    test('AUDIT 1: Hang-Cella független életereje és ANSI-szűrő integritása', () async {
      final healthUrl = Uri.parse('http://127.0.0.1:5005/health');
      
      try {
        final res = await http.get(healthUrl).timeout(const Duration(seconds: 3));
        expect(res.statusCode, 200, 
            reason: 'A hang-cella válaszolt, de nem 200 OK státusszal.');
        
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        expect(body['status'], 'ALIVE', 
            reason: 'A hang-cella életereje hibás állapotot jelentett.');
      } on SocketException {
        // Ha a szerver nem fut, a teszt rámutat az önálló cella hiányára
        fail('KRITIKUS: A Hang-Cella (python_tts_uploader_server.py) nem fut a háttérben az 5005-ös porton!');
      }

      // Ellenőrizzük, hogy a beszéd-végpont kezeli-e a vezérlőkarakterek kiszűrését
      final speakUrl = Uri.parse('http://127.0.0.1:5005/think_and_speak');
      final dirtyPayload = jsonEncode({
        'query': '\x1b[0;32mki vagy te\x1b[0m' // ANSI escape kódos szennyezett bemenet
      });

      final speakRes = await http.post(
        speakUrl,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: dirtyPayload,
      );

      expect(speakRes.statusCode, 200);
      final speakBody = jsonDecode(utf8.decode(speakRes.bodyBytes));
      final cleanAnswer = speakBody['answer'].toString();
      
      // A kimenet nem tartalmazhat konzolvezérlő karaktereket
      expect(cleanAnswer.contains('\x1b'), isFalse, 
          reason: 'A hang-cella átengedte az ANSI terminálvezérlő karaktereket!');
    });

    // 2. CELLA AUDIT: A Szinapszis (Orchestrator) állapotkezelése
    test('AUDIT 2: GeneviewOrchestrator sejtkommunikáció és állapotgép', () {
      final orchestrator = GeneviewOrchestrator();
      
      // Alaphelyzeti metabolizmus vizsgálata
      expect(orchestrator.status, CellStatus.idle);
      expect(orchestrator.isSpeaking, isFalse);
      expect(orchestrator.activeFrame, 'assets/images/Geneview.png');
      
      // Erőforrások tiszta lezárása
      orchestrator.dispose();
    });

    // 3. CELLA AUDIT: Vizuális Cella (Presence Nexus) és Pepper\'s Ghost kompatibilitás
    testWidgets('AUDIT 3: Vizuális Cella piramis és prizma elrendezés', (WidgetTester tester) async {
      const testFrame = 'assets/images/Geneview.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HologramDisplayScreen(
              activeFrame: testFrame,
              isSpeaking: false,
            ),
          ),
        ),
      );

      // A felületnek azonnal a 4-oldalas piramis elrendezést kell renderelnie
      expect(find.byType(Image), findsNWidgets(4),
          reason: 'A Vizuális Cella nem hozta létre a 4 oldalas Pepper\'s Ghost vetületet.');

      // Standard módra váltás tesztelése
      await tester.tap(find.text('STANDARD'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);

      // Prizma módra váltás tesztelése
      await tester.tap(find.text('PRISM SPLIT'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(2));
    });
  });
}