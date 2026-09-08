import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Beszédszintézishez és vizuális mimikához használt akusztikai/prozódiai profil
class ProsodyParameters {
  final double pitchHz;
  final double speechRate;
  final double volumeGainDb;
  final double warmthResonance;
  final double breathiness;
  final String cadenceInflection;

  // Mobil Web Speech API / TTS szorzók (0.0 - 2.0 skála)
  final double ttsPitchMultiplier;
  final double ttsRateMultiplier;

  const ProsodyParameters({
    this.pitchHz = 185.0,
    this.speechRate = 1.0,
    this.volumeGainDb = 0.0,
    this.warmthResonance = 0.8,
    this.breathiness = 0.15,
    this.cadenceInflection = "gentle",
    this.ttsPitchMultiplier = 1.0,
    this.ttsRateMultiplier = 0.88,
  });
}

/// ZSENI SPEECH PROSODY & EMOTIONAL CADENCE MOTOR (FLUTTER / MOBILE)
class SpeechProsodyEngine {
  SpeechProsodyEngine() {
    debugPrint("[ProsodyEngine] Mobil prozódia és intonációs motor inicializálva.");
  }

  /// Gömbi koordináták leképezése dinamikus beszédjellemzőkre
  /// - xEastWest: Empátia és melegség
  /// - yNorthSouth: Ráció és feszes intonáció
  /// - zZenith: Stabilitás és hangerő
  ProsodyParameters computeProsodyFromSphere({
    double xEastWest = 0.0,
    double yNorthSouth = 0.0,
    double zZenith = 0.0,
    double baseRate = 0.88, // A magyar Mariska hanghoz kalibrált alapérték
  }) {
    // 1. Hangmagasság moduláció (140 Hz - 240 Hz skála)
    final rawPitch = 185.0 + (zZenith * 3.5) - (yNorthSouth * 2.0);
    final pitch = rawPitch.clamp(140.0, 240.0);

    // 2. Tempó moduláció
    final rawRate = baseRate + (yNorthSouth * 0.03) - (xEastWest * 0.02);
    final rate = rawRate.clamp(0.75, 1.25);

    // 3. Melegség és empátiás formáns
    final warmth = (0.7 + (xEastWest * 0.08)).clamp(0.2, 1.0);

    // 4. Légzési lágyság
    final breath = (0.15 + (xEastWest * 0.04)).clamp(0.05, 0.5);

    // 5. Stílus meghatározása
    String inflection;
    if (xEastWest > 1.5) {
      inflection = "warm_intimate";
    } else if (yNorthSouth > 1.5) {
      inflection = "precise_socratic";
    } else {
      inflection = "grounded_presence";
    }

    // Mobil TTS motorhoz átszámolt arányok (185 Hz -> 1.0 magasság)
    final ttsPitch = (pitch / 185.0).clamp(0.8, 1.3);

    return ProsodyParameters(
      pitchHz: pitch,
      speechRate: rate,
      volumeGainDb: (zZenith * 0.2).clamp(-3.0, 3.0),
      warmthResonance: warmth,
      breathiness: breath,
      cadenceInflection: inflection,
      ttsPitchMultiplier: ttsPitch,
      ttsRateMultiplier: rate,
    );
  }

  /// SSML leíró generálása
  Map<String, dynamic> generateMetadata(String text, ProsodyParameters params) {
    return {
      "raw_text": text,
      "prosody": {
        "pitch_hz": params.pitchHz.toStringAsFixed(1),
        "rate": params.speechRate.toStringAsFixed(2),
        "volume_db": params.volumeGainDb.toStringAsFixed(1),
        "warmth": params.warmthResonance.toStringAsFixed(2),
        "style": params.cadenceInflection,
      },
      "ssml_markup": '<prosody pitch="${params.pitchHz.toStringAsFixed(1)}Hz" rate="${params.speechRate.toStringAsFixed(2)}">$text</prosody>',
    };
  }
}