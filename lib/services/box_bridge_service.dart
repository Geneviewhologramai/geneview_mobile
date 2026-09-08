import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BoxHarmonizeResponse {
  final double pulseFrequencyHz;
  final double meshIntensityGain;
  final double colorTempKelvin;
  final double speechRateMultiplier;
  final double valence;

  BoxHarmonizeResponse({
    required this.pulseFrequencyHz,
    required this.meshIntensityGain,
    required this.colorTempKelvin,
    required this.speechRateMultiplier,
    required this.valence,
  });

  factory BoxHarmonizeResponse.fromJson(Map<String, dynamic> json, double inputValence) {
    final visuals = json['hologram_visuals'] as Map<String, dynamic>? ?? {};
    final audio = json['audio_synthesis'] as Map<String, dynamic>? ?? {};

    return BoxHarmonizeResponse(
      pulseFrequencyHz: (visuals['pulse_frequency_hz'] ?? 0.25).toDouble(),
      meshIntensityGain: (visuals['mesh_intensity_gain'] ?? 1.0).toDouble(),
      colorTempKelvin: (visuals['color_temperature_kelvin'] ?? 5000.0).toDouble(),
      speechRateMultiplier: (audio['speech_rate_multiplier'] ?? 1.0).toDouble(),
      valence: inputValence,
    );
  }
}

class BoxBridgeService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<BoxHarmonizeResponse?> sendEmotionalTelemetry({
    required double valence,
    required double arousal,
    double pitchVariance = 1.0,
    double voiceIntensity = 0.8,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/emotional-harmonizer/harmonize');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_valence': valence,
          'user_arousal': arousal,
          'voice_pitch_variance': pitchVariance,
          'voice_intensity': voiceIntensity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BoxHarmonizeResponse.fromJson(data, valence);
      } else {
        debugPrint('[BoxBridge] Backend HTTP kód: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BoxBridge] Kapcsolódási hiba: $e');
    }
    return null;
  }
}