// lib/core/math/mathematical_experience_engine.dart
import 'dart:math' as math;

class MathematicalExperienceEngine {
  static double computeManifoldCurvature(double cognitiveLoad, double emotionalTension) {
    return math.sqrt(math.pow(cognitiveLoad, 2) + math.pow(emotionalTension, 2)).clamp(0.0, 1.414);
  }
}