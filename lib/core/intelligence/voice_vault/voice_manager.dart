import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'voice_profile.dart';

class VoiceManager extends ChangeNotifier {
  VoiceProfile _activeVoice = VoiceCatalog.builtInVoices[0];
  final String _ttsConfigUrl = 'http://127.0.0.1:5005/set_voice';

  VoiceProfile get activeVoice => _activeVoice;

  Future<void> selectVoice(VoiceProfile voice) async {
    _activeVoice = voice;
    notifyListeners();

    try {
      await http.post(
        Uri.parse(_ttsConfigUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': voice.modelName,
          'language': voice.languageCode,
        }),
      );
    } catch (_) {}
  }

  /// Hangutasítás felismerése a beszéd alapján
  bool handleVoiceCommand(String spokenText) {
    final lower = spokenText.toLowerCase();

    // 1. Nyelvváltási parancsok
    if (lower.contains('beszélj angolul') || lower.contains('speak english')) {
      final target = VoiceCatalog.builtInVoices.firstWhere(
        (v) => v.languageCode == 'en_US' && v.gender == _activeVoice.gender,
        orElse: () => VoiceCatalog.builtInVoices[4],
      );
      selectVoice(target);
      return true;
    }

    if (lower.contains('beszélj magyarul') || lower.contains('speak hungarian')) {
      final target = VoiceCatalog.builtInVoices.firstWhere(
        (v) => v.languageCode == 'hu_HU' && v.gender == _activeVoice.gender,
        orElse: () => VoiceCatalog.builtInVoices[0],
      );
      selectVoice(target);
      return true;
    }

    // 2. Konkrét hangok nevének felismerése
    for (final voice in VoiceCatalog.builtInVoices) {
      final firstName = voice.displayName.split(' ')[0].toLowerCase();
      if (lower.contains(firstName) && (lower.contains('hang') || lower.contains('voice') || lower.contains('vált'))) {
        selectVoice(voice);
        return true;
      }
    }

    return false;
  }
}