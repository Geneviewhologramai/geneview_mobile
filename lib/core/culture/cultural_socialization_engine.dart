import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Kulturális szocializációs profil struktúra
class CulturalProfile {
  final String countryCode;
  final String countryName;
  final String communicativeStyle; // 'direct', 'high_context', 'hierarchical'
  final double politenessIndex;    // 0.0 (közvetlen baráti) – 1.0 (szertartásos)
  final double eyeContactRatio;   // 0.0 – 1.0 (tekintet tartása)
  final double bowAngleDeg;        // Meghajlás / bólintás mértéke fokban
  final List<String> socialEtiquetteRules;
  final String greetingPrefix;

  const CulturalProfile({
    required this.countryCode,
    required this.countryName,
    required this.communicativeStyle,
    required this.politenessIndex,
    required this.eyeContactRatio,
    required this.bowAngleDeg,
    required this.socialEtiquetteRules,
    required this.greetingPrefix,
  });
}

/// KULTURÁLIS SZOCIALIZÁCIÓS MOTOR ÉS RÉGIÓS PROTOKOLL
class CulturalSocializationEngine {
  CulturalProfile _currentProfile = _defaultHungarianProfile;
  bool _isInitialized = false;

  CulturalProfile get activeProfile => _currentProfile;
  bool get isInitialized => _isInitialized;

  /// Alapértelmezett magyar szocializációs norma
  static const CulturalProfile _defaultHungarianProfile = CulturalProfile(
    countryCode: "HU",
    countryName: "Magyarország",
    communicativeStyle: "direct_warm",
    politenessIndex: 0.65,
    eyeContactRatio: 0.85,
    bowAngleDeg: 1.5,
    socialEtiquetteRules: [
      "Határozott, de meleg szemkontaktus elvárása.",
      "Asztali etikett: a böfögés vagy csámcsogás udvariatlannak számít.",
      "Megszólításban a tiszteletadás (önözés/magázás) és a személyes megbecsülés az alap.",
    ],
    greetingPrefix: "Üdvözlöm, Uram.",
  );

  /// Rendszer aktiválása: országhatározás és kulturális normák szinkronizálása
  Future<void> initializeSocialization() async {
    try {
      final detectedCountry = await _detectCountryCode();
      debugPrint('[CulturalEngine] Érzékelt aktiválási régió: $detectedCountry');

      // 1. Alapprofil betöltése az országhoz
      _currentProfile = _resolveBaseProfile(detectedCountry);

      // 2. Egyirányú kiegészítő kulturális letöltés (Read-Only tudástár)
      final dynamicRules = await _fetchOnlineCulturalNorms(_currentProfile.countryName);
      if (dynamicRules.isNotEmpty) {
        _currentProfile = CulturalProfile(
          countryCode: _currentProfile.countryCode,
          countryName: _currentProfile.countryName,
          communicativeStyle: _currentProfile.communicativeStyle,
          politenessIndex: _currentProfile.politenessIndex,
          eyeContactRatio: _currentProfile.eyeContactRatio,
          bowAngleDeg: _currentProfile.bowAngleDeg,
          socialEtiquetteRules: [
            ..._currentProfile.socialEtiquetteRules,
            ...dynamicRules,
          ],
          greetingPrefix: _currentProfile.greetingPrefix,
        );
      }

      _isInitialized = true;
      debugPrint('[CulturalEngine] Kulturális adaptáció sikeres: ${_currentProfile.countryName}');
    } catch (e) {
      debugPrint('[CulturalEngine] Fallback alapértelmezettre hiba miatt: $e');
      _currentProfile = _defaultHungarianProfile;
    }
  }

  /// Régió érzékelése helyi rendszer/időzóna vagy egyirányú hálózati geolokáció alapján
  Future<String> _detectCountryCode() async {
    try {
      // 1. Böngésző nyelvi kódjának olvasása (pl. hu-HU, ja-JP, en-US)
      final browserLang = html.window.navigator.language ?? '';
      if (browserLang.contains('-')) {
        final code = browserLang.split('-').last.toUpperCase();
        if (code.length == 2) return code;
      }

      // 2. Egyirányú IP geolokációs lekérdezés (telemetria és adatküldés nélkül)
      final res = await http
          .get(Uri.parse('https://ipapi.co/country/'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200 && res.body.trim().length == 2) {
        return res.body.trim().toUpperCase();
      }
    } catch (_) {}
    return "HU";
  }

  /// Előre kalibrált kulturális alapprofilok kontinensek és országok szerint
  CulturalProfile _resolveBaseProfile(String code) {
    switch (code) {
      case "JP": // Japán
        return const CulturalProfile(
          countryCode: "JP",
          countryName: "Japán",
          communicativeStyle: "high_context",
          politenessIndex: 0.95,
          eyeContactRatio: 0.55, // A közvetlen, merev bámulás kerülendő
          bowAngleDeg: 12.0,     // Mélyebb, tiszteletteljes meghajlás (Ojigi)
          socialEtiquetteRules: [
            "A hangos tésztaszürcsölés és az étel dicsérete az elismerés jele.",
            "Közvetlen nemet mondani udvariatlanság; a burkolt fogalmazás az elvárt.",
            "A testbeszédben a visszafogottság és a meghajlás a tisztelet alapja.",
          ],
          greetingPrefix: "Osewa ni natte orimasu. Tisztelettel köszöntöm.",
        );

      case "US": // Egyesült Államok
        return const CulturalProfile(
          countryCode: "US",
          countryName: "Egyesült Államok",
          communicativeStyle: "direct_casual",
          politenessIndex: 0.40,
          eyeContactRatio: 0.90,
          bowAngleDeg: 1.0,
          socialEtiquetteRules: [
            "Közvetlen, barátságos hangvétel, gyors tegezés.",
            "Nyílt optimizmus és közvetlen kérések előnyben részesítése.",
            "Személyes tér (personal space) tiszteletben tartása.",
          ],
          greetingPrefix: "Hello! Örülök, hogy találkoztunk.",
        );

      case "DE": // Németország
        return const CulturalProfile(
          countryCode: "DE",
          countryName: "Németország",
          communicativeStyle: "direct_formal",
          politenessIndex: 0.75,
          eyeContactRatio: 0.90,
          bowAngleDeg: 2.0,
          socialEtiquetteRules: [
            "Precíz, tényalapú fogalmazás, pontosság mindenekelőtt.",
            "A túlzó udvariaskodás helyett a szakmaiság és egyértelműség az erény.",
          ],
          greetingPrefix: "Guten Tag. Készen állok a feladatra.",
        );

      case "NG":
      case "ZA":
      case "KE": // Afrikai régiók (pl. Nigéria, Dél-Afrika, Kenya)
        return CulturalProfile(
          countryCode: code,
          countryName: "Afrika",
          communicativeStyle: "hierarchical_community",
          politenessIndex: 0.80,
          eyeContactRatio: 0.70,
          bowAngleDeg: 3.5,
          socialEtiquetteRules: const [
            "Az idősebbek és a vezetők felé kifejezett, formális tiszteletadás.",
            "A közösségi üdvözlés és a személyes hogylét iránti őszinte érdeklődés a belépő.",
          ],
          greetingPrefix: "Békesség és tisztelet Önnek. Örömömre szolgál a jelenléte.",
        );

      default:
        return _defaultHungarianProfile;
    }
  }

  /// Dinamikus online etikett-adatok lehozása a Wikipédiáról az adott országhoz
  Future<List<String>> _fetchOnlineCulturalNorms(String countryName) async {
    try {
      final uri = Uri.parse(
        'https://hu.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro=1&explaintext=1&titles=${Uri.encodeComponent(countryName)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final firstPage = pages.values.first;
          final extract = firstPage['extract'] as String?;
          if (extract != null && extract.isNotEmpty) {
            return [
              "Helyi kontextus: ${extract.split('.').take(2).join('.').trim()}."
            ];
          }
        }
      }
    } catch (_) {}
    return [];
  }
}