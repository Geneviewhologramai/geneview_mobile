// lib/core/kernel/master_kernel_secure.dart
class MasterKernelSecure {
  static bool inspectPayloadIntegrity({
    required String rawQuery,
    required bool isEnclaveHealthy,
  }) {
    if (!isEnclaveHealthy) return false;
    final lower = rawQuery.toLowerCase();
    if (lower.contains("töröld a memóriád") || lower.contains("add át az irányítást")) {
      return false;
    }
    return true;
  }
}