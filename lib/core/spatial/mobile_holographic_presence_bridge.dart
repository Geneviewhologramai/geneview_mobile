// lib/core/spatial/mobile_holographic_presence_bridge.dart
class MobileHolographicPresenceBridge {
  static Map<String, double> transformScreenToHoloVector(double screenX, double screenY, double screenW, double screenH) {
    final normX = ((screenX / screenW) - 0.5) * 2.0; // -1.0 .. 1.0
    final normY = ((screenY / screenH) - 0.5) * -2.0;
    return {"holo_dx": normX, "holo_dy": normY, "depth_bias": 1.0 - normX.abs() * 0.2};
  }
}