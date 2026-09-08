import 'contracts/i_brain_vault.dart';
import 'contracts/i_voice_vault.dart';
import 'contracts/i_presence_vault.dart';

class GeneviewOrchestrator {
  final IBrainVault brainVault;
  final IVoiceVault voiceVault;
  final IPresenceVault presenceVault;

  GeneviewOrchestrator({
    required this.brainVault,
    required this.voiceVault,
    required this.presenceVault,
  });

  Future<String> handleUserInput(String text) async {
    // 1. Állapot: Gondolkodás
    presenceVault.updateState(PresenceState.thinking);

    // 2. Intelligencia trezor feldolgozása
    final response = await brainVault.processThought(text);

    // 3. Állapot: Beszéd + Hang trezor aktiválása
    presenceVault.updateState(PresenceState.speaking);
    await voiceVault.speak(response);

    // 4. Visszatérés alapállapotba
    presenceVault.updateState(PresenceState.idle);

    return response;
  }
}