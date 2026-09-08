import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class UniverseStar {
  final String id;
  final String label;
  final String domain;
  double x;
  double y;
  double z;
  double intensity;
  double frequency;

  UniverseStar({
    required this.id,
    required this.label,
    required this.domain,
    required this.x,
    required this.y,
    required this.z,
    this.intensity = 1.0,
    this.frequency = 1.0,
  });

  double get distanceFromCore => sqrt(x * x + y * y + z * z);

  int get layerIndex {
    const double maxRadius = 17.32; // sqrt(10^2 + 10^2 + 10^2)
    final layer = (distanceFromCore / maxRadius * 36).ceil();
    return layer.clamp(1, 36);
  }

  void pulseTick(double time) {
    final heartbeat = sin(time * (60.0 / 60.0) * 2 * pi);
    final delta = heartbeat * 0.015 * frequency;
    x = (x + delta).clamp(-10.0, 10.0);
    y = (y + delta).clamp(-10.0, 10.0);
    z = (z + delta).clamp(-10.0, 10.0);
  }
}

class GeneviewUniverseState extends ChangeNotifier {
  final Map<String, UniverseStar> _stars = {};
  Timer? _heartbeatTimer;
  double _simulationTime = 0.0;
  UniverseStar? _lastDiscoveredStar;

  UniverseStar? get lastDiscoveredStar => _lastDiscoveredStar;
  List<UniverseStar> get allStars => _stars.values.toList();

  GeneviewUniverseState() {
    _seedCoreAnchors();
    _startHeartbeatLoop();
  }

  void _seedCoreAnchors() {
    _register('tudastar_core', 'Tudástár', 'TUDÁSTÁR', 0.5, -0.2, 0.4, 4.0);
    _register('csalad_core', 'Család', 'CSALÁD', 0.2, 2.5, 0.8, 4.5);
    _register('szuverenitas', 'Agymosás Ellen', 'AGYMOSÁS ELLEN', 5.0, 4.2, 2.0, 3.8);
    _register('magany', 'Magány Mélysége', 'MAGÁNY', -6.5, -2.0, 1.5, 3.0);
  }

  void _register(String id, String label, String domain, double x, double y, double z, double intensity) {
    _stars[id] = UniverseStar(
      id: id,
      label: label,
      domain: domain,
      x: x,
      y: y,
      z: z,
      intensity: intensity,
      frequency: 1.0,
    );
  }

  void _startHeartbeatLoop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _simulationTime += 0.05;
      for (final star in _stars.values) {
        star.pulseTick(_simulationTime);
      }
      notifyListeners();
    });
  }

  UniverseStar discoverStar({required String label, required String domain, required double x, required double y, required double z}) {
    final id = 'star_${DateTime.now().millisecondsSinceEpoch}';
    final star = UniverseStar(
      id: id,
      label: label,
      domain: domain,
      x: x.clamp(-10.0, 10.0),
      y: y.clamp(-10.0, 10.0),
      z: z.clamp(-10.0, 10.0),
      intensity: 3.0,
      frequency: 1.2,
    );
    _stars[id] = star;
    _lastDiscoveredStar = star;
    notifyListeners();
    return star;
  }

  List<UniverseStar> getNearestToCore({int count = 3}) {
    final list = _stars.values.toList();
    list.sort((a, b) => a.distanceFromCore.compareTo(b.distanceFromCore));
    return list.take(count).toList();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}