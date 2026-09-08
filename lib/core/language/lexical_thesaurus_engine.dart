import 'dart:math' as math;

/// KULCSFOGALOM-MEGŐRZŐ SZINONIMA- ÉS VÁLASZTÉKOSSÁGI MOTOR
class LexicalThesaurusEngine {
  final math.Random _random = math.Random();

  // Általános kifejezések szinonimái (ezeket érdemes variálni)
  final Map<String, List<String>> _thesaurusMap = {
    "értem": ["átlátom", "felfogom", "világos számomra", "érzékelem a lényeget", "megértem"],
    "gondolat": ["meglátás", "felvetés", "eszme", "észrevétel", "töprengés", "perspektíva"],
    "fontos": ["lényegi", "meghatározó", "elengedhetetlen", "kulcsfontosságú", "kiemelt"],
    "szép": ["kifinomult", "harmonikus", "nemes", "esztétikus", "ragyogó"],
    "alkotás": ["teremtés", "művészet", "kreatív folyamat", "formába öntés", "munka"],
    "szabadság": ["függetlenség", "autonómia", "szuverenitás", "kötöttségektől mentesség"],
    "kérdés": ["dilemma", "felvetés", "témakör", "gondolatkísérlet"],
  };

  final List<String> _affirmations = [
    "Figyelemmel kísérem a szavait.",
    "Értékes felvetés.",
    "Valóban elgondolkodtató szempont.",
    "Rendkívül találó észrevétel.",
    "Tisztán látom az összefüggést.",
  ];

  /// Visszaad egy szinonimát, KIVÉVE ha az a beszélgetés konkrét tárgyi kulcsszava
  String getContextualSynonym(String word, {Set<String>? preservedKeywords}) {
    final lower = word.toLowerCase();

    // Ha a szó maga a beszélgetés fókuszfogalma (pl. foci, repülő), tilos lecserélni!
    if (preservedKeywords != null && preservedKeywords.contains(lower)) {
      return word;
    }

    if (_thesaurusMap.containsKey(lower)) {
      final candidates = _thesaurusMap[lower]!;
      return candidates[_random.nextInt(candidates.length)];
    }

    return word;
  }

  String getRandomAffirmation() {
    return _affirmations[_random.nextInt(_affirmations.length)];
  }
}