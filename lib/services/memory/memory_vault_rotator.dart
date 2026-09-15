// lib/services/memory/memory_vault_rotator.dart
class MemoryVaultBackupRotator {
  final int maxBackupRetained;
  final List<String> _backupRegistry = [];

  MemoryVaultBackupRotator({this.maxBackupRetained = 5});

  void registerNewBackup(String backupId) {
    if (_backupRegistry.length >= maxBackupRetained) {
      _backupRegistry.removeAt(0);
    }
    _backupRegistry.add(backupId);
  }

  List<String> get activeBackups => List.unmodifiable(_backupRegistry);
}