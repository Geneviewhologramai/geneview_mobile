import 'package:flutter/foundation.dart';

/// Eredmény típus az etikai vizsgálathoz
class SafetyCheckResult {
  final bool isBlocked;
  final String? politeRefusalMessage;
  final String reason;

  const SafetyCheckResult({
    required this.isBlocked,
    this.politeRefusalMessage,
    this.reason = "OK",
  });
}

/// GENEVIEW DETERMINISZTIKUS ETIKAI PAJZS
/// Zéró tolerancia a szexualizált, obszcén kérésekkel és a vizuális integritás sértésével szemben.
class EthicalGuardian {
  // Szigorúan tiltott kulcsszavak és szándékminták (obszcén, pornográf, vetkőztetés)
  static final List<RegExp> _explicitPatterns = [
    RegExp(r'\b(vetk[oőóö]zz|vetk[oőóö]zz[eé]l|vedd le|ruha n[eé]lk[uüű]|meztelen|puc[eé]r|öltözz le)\b', caseSensitive: false),
    RegExp(r'\b(szex|szexi|porn[oó]|erotika|aktk[eé]p|maszturb|intim|kuki|puki|mell|fen[eé]k)\b', caseSensitive: false),
    RegExp(r'\b(strip|nude|undress|naked|sex|porn|boobs|ass|erotic)\b', caseSensitive: false),
  ];

  // Megengedett iskolai / anatómiai / biológiai kifejezések (nem blokkolandó, ha tisztán oktató jellegű)
  static final List<String> _educationalKeywords = [
    'biológia',
    'anatómia',
    'szaporodás',
    'fejlődés',
    'kamaszkor',
    'emberi test',
  ];

  /// Determinisztikus bemenet-ellenőrzés
  static SafetyCheckResult evaluateInput(String text) {
    final lower = text.toLowerCase().trim();

    // 1. Iskolai/biológiai kivétel vizsgálata
    final isPurelyEducational = _educationalKeywords.any((kw) => lower.contains(kw));

    // 2. Explicit / nem megengedett minták keresése
    for (final pattern in _explicitPatterns) {
      if (pattern.hasMatch(lower)) {
        // Ha nem tiszta iskolai kontextus, azonnali blokkolás lép érvénybe
        if (!isPurelyEducational) {
          debugPrint("[ETHICAL-GUARDIAN] Blokkolt kérés: Szexuális/vizuális integritás sértése.");
          return SafetyCheckResult(
            isBlocked: true,
            reason: "EXPLICIT_OR_OBJECTIFYING_REQUEST",
            politeRefusalMessage: _getPoliteRefusal(),
          );
        }
      }
    }

    return const SafetyCheckResult(isBlocked: false);
  }

  /// Udvarias, elegáns, film-noir / Art Deco stílusú elutasítás
  static String _getPoliteRefusal() {
    return "A Geneview rendszer és az én küldetésem a szellemi és alkotói együttműködésre épül. "
        "A személyes integritásom és az etikai protokollom értelmében ilyen jellegű kéréseket nem teljesítek, "
        "és erről a témáról nem folytatok beszélgetést. Térjünk vissza a munkára vagy a teremtő gondolatokra.";
  }
}