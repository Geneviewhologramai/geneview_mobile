class PresenceProfile {
  final double depthFieldResolution;
  final bool isCharging;

  PresenceProfile({required this.depthFieldResolution, required this.isCharging});
}

class FuturePresenceCore {
  static PresenceProfile computePresenceProfile(double batteryLevel, bool isCharging) {
    return PresenceProfile(
      depthFieldResolution: isCharging ? 1080.0 : 720.0,
      isCharging: isCharging,
    );
  }
}
