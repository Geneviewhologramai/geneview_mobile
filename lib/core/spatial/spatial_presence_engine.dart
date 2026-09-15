// lib/core/spatial/spatial_presence_engine.dart
class SpatialPresenceEngine {
  static bool isUserInDirectFocalZone(double distanceMeters, double lateralAngleDeg) {
    return distanceMeters >= 0.3 && distanceMeters <= 3.5 && lateralAngleDeg.abs() <= 35.0;
  }
}