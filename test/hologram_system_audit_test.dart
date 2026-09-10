import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geneview_mobile/presentation/hologram_display_screen.dart';

void main() {
  group('GENEVIEW Hologram Rendszer & Architektúra Audit', () {
    
    // -------------------------------------------------------------
    // 1. TESZT: Belépési pont (main.dart) bekötöttségének vizsgálata
    // -------------------------------------------------------------
    test('AUDIT 1: lib/main.dart bekötöttségének ellenőrzése', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue, 
          reason: 'HIBA: A lib/main.dart belépési pont nem található!');

      final content = mainFile.readAsStringSync();

      // Ellenőrizzük, hogy importálva van-e a prezentációs képernyő
      final hasImport = content.contains('hologram_display_screen.dart');
      expect(hasImport, isTrue, 
          reason: 'KRITIKUS HIBA: A lib/main.dart NEM importálja a HologramDisplayScreen-t! A komponens el van vágva a futó rendszertől.');

      // Ellenőrizzük, hogy a widget ténylegesen meg van-e hívva a fa építésekor
      final hasWidgetUsage = content.contains('HologramDisplayScreen(');
      expect(hasWidgetUsage, isTrue, 
          reason: 'KRITIKUS HIBA: A HologramDisplayScreen nincs példányosítva a main.dart widget fájában!');
    });

    // -------------------------------------------------------------
    // 2. TESZT: Típusdefiníciók és szilárd interfész ellenőrzése
    // -------------------------------------------------------------
    testWidgets('AUDIT 2: Típusdefiníciók és paraméter-kompatibilitás', (WidgetTester tester) async {
      // Ha típusdefiníciós hiba vagy hiányzó típus (pl. PresenceState) lenne,
      // ez a blokk már a fordítás (build) fázisban elbukna.
      const testFrame = 'assets/images/Geneview.png';
      const isSpeakingTest = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HologramDisplayScreen(
              activeFrame: testFrame,
              isSpeaking: isSpeakingTest,
            ),
          ),
        ),
      );

      // Ellenőrizzük, hogy a widget sikeresen felépült-e a memóriában
      expect(find.byType(HologramDisplayScreen), findsOneWidget);
    });

    // -------------------------------------------------------------
    // 3. TESZT: Vizuális architektúra és vetítési módok kompatibilitása
    // -------------------------------------------------------------
    testWidgets('AUDIT 3: 4-oldalas Piramis és Prizma vetítési módok auditja', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HologramDisplayScreen(
              activeFrame: 'assets/images/Geneview.png',
              isSpeaking: false,
            ),
          ),
        ),
      );

      // 3.1. Alapértelmezett indítás: PYRAMID 4X mód meglétének vizsgálata
      // A Pepper's Ghost optikához pontosan 4 db vetületre van szükség (Fel, Le, Balra, Jobbra)
      final imagesInPyramid = find.byType(Image);
      expect(imagesInPyramid, findsNWidgets(4),
          reason: 'ARCHITEKTÚRA HIBA: A PYRAMID 4X módban pontosan 4 darab vetületnek (Image) kell megjelennie a 4 üveglaphoz!');

      // Ellenőrizzük, hogy a forgatási transzformációk (Transform.rotate) érvényesülnek-e
      expect(find.byType(Transform), findsWidgets);

      // 3.2. Átváltás STANDARD (sima nézet) módra
      final standardBtn = find.text('STANDARD');
      expect(standardBtn, findsOneWidget);
      await tester.tap(standardBtn);
      await tester.pumpAndSettle();

      // Standard módban csak 1 darab középső képnek szabad lennie
      expect(find.byType(Image), findsOneWidget,
          reason: 'ARCHITEKTÚRA HIBA: STANDARD nézetben pontosan 1 figurának kell megjelennie!');

      // 3.3. Átváltás PRISM SPLIT (kettős prizma) módra
      final prismBtn = find.text('PRISM SPLIT');
      expect(prismBtn, findsOneWidget);
      await tester.tap(prismBtn);
      await tester.pumpAndSettle();

      // Kettős prizma módban pontosan 2 vetületnek kell lennie
      expect(find.byType(Image), findsNWidgets(2),
          reason: 'ARCHITEKTÚRA HIBA: PRISM SPLIT módban pontosan 2 képi vetületnek kell lennie!');
    });
  });
}