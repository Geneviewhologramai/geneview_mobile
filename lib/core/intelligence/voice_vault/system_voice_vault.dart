import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:geneview_mobile/core/contracts/i_voice_vault.dart';

class SystemVoiceVault implements IVoiceVault {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _speakUrl = 'http://127.0.0.1:5005/speak';
  final String _audioUrl = 'http://127.0.0.1:5005/get_audio';

  @override
  Future<void> speak(String text) async {
    try {
      // 1. Kérés küldése a Python női TTS motornak a hang generálására
      final response = await http.post(
        Uri.parse(_speakUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        // 2. A legenerált női WAV hangfájl azonnali lejátszása (cache bypass időbélyeggel)
        final playUrl = '$_audioUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        await _audioPlayer.play(UrlSource(playUrl));
      } else {
        print('TTS hiba a szerveren: ${response.statusCode}');
      }
    } catch (e) {
      print('Nem sikerült elérni a Python hangmotort: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Hiba a hang megállításakor: $e');
    }
  }
}