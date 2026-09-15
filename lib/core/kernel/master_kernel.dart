// lib/core/kernel/master_kernel.dart
class MasterKernel {
  static bool shouldFormulateSocraticCounterQuery(String query, int turnDepth) {
    if (turnDepth > 3) return false;
    final lower = query.toLowerCase();
    return lower.contains("szerinted") || lower.contains("mi az igazság");
  }
}