import '../../core/contracts/i_voice_vault.dart';

class SystemVoiceVault implements IVoiceVault {
  // Később ide köthető be közvetlenül az Audioplayer vagy a Piper ONNX motor
  @override
  Future<void> speak(String text) async {
    // Hangsugárzási hívás helye
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> stop() async {
    // Hang azonnali megszakítása
  }
}