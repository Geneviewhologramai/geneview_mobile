// lib/core/system/onion_architecture_v36.dart
class OnionArchitectureV36 {
  static bool verifyLayerHierarchy({required int activeDepth}) {
    return activeDepth >= 1 && activeDepth <= 36;
  }
}