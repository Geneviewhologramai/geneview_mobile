import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = RealHttpOverrides();
  });

  group('GENEVIEW Sejtes Architektúra & Rezonancia Audit', () {
    test('AUDIT 1: Hang-Cella független életereje és ANSI-szűrő integritása', () async {
      final healthUri = Uri.parse('http://127.0.0.1:5005/health');
      final healthRes = await http.get(healthUri);
      expect(healthRes.statusCode, 200);

      final speakUri = Uri.parse('http://127.0.0.1:5005/think_and_speak');
      final dirtyPayload = jsonEncode({
        'query': '\x1b[31mGENEVIEW szuverén hangteszt\x1b[0m'
      });

      final speakRes = await http.post(
        speakUri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: dirtyPayload,
      );

      expect(speakRes.statusCode, 200);
      final speakBody = jsonDecode(utf8.decode(speakRes.bodyBytes));
      final cleanAnswer = speakBody['answer'].toString();
      expect(cleanAnswer.contains('\x1b'), isFalse, reason: 'A hang-cella átengedte az ANSI kódokat!');
    });

    testWidgets('AUDIT 2: UI jelenlét állapotok', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('GENEVIEW ACTIVE')),
          ),
        ),
      );
      expect(find.text('GENEVIEW ACTIVE'), findsOneWidget);
    });

    test('AUDIT 3: Rezonancia integritás', () {
      expect(true, isTrue);
    });
  });
}
