// lib/core/spatial/omni_field_orchestrator.dart
class OmniFieldSnapshot {
  final List<double> spatialDirectionVector;
  final double emotionalValence;

  OmniFieldSnapshot(this.spatialDirectionVector, this.emotionalValence);
}

class OmniFieldOrchestrator {
  static OmniFieldSnapshot computeField(double userAngleRad, double moodValence) {
    return OmniFieldSnapshot([userAngleRad, 1.0, 0.5], moodValence);
  }
}