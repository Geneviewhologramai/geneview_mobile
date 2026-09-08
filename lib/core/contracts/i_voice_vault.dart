abstract class IVoiceVault {
  Future<void> speak(String text);
  Future<void> stop();
}