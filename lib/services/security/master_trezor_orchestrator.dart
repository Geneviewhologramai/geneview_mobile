// lib/services/security/master_trezor_orchestrator.dart
class MasterTrezorOrchestrator {
  final Set<String> _unlockedVaults = {};

  bool unlockVault(String vaultId, String keyHash) {
    if (keyHash.isNotEmpty) {
      _unlockedVaults.add(vaultId);
      return true;
    }
    return false;
  }

  bool isVaultAccessible(String vaultId) => _unlockedVaults.contains(vaultId);
}