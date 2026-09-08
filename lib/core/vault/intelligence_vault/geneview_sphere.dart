import 'dart:math';

/// A 36 belső réteg szintjei
class SphereLayer {
  final int index; // 1-től 36-ig
  final String label;
  final double radiusRangeStart;
  final double radiusRangeEnd;

  const SphereLayer({
    required this.index,
    required this.label,
    required this.radiusRangeStart,
    required this.radiusRangeEnd,
  });
}

/// Egyetlen tudás-, szó- vagy érzelem-csomópont a gömbön belül
class SphereNode {
  final String id;
  final String content;
  final String category; // 'emotion', 'concept', 'knowledge', 'word'
  
  // 3D koordináták a [-10.0, +10.0] tartományban
  double x; // Kelet (+) / Nyugat (-)
  double y; // Észak (+) / Dél (-)
  double z; // Magasság (+) / Mélység (-)
  
  double frequency; // Rezgési frekvencia
  double intensity;

  SphereNode({
    required this.id,
    required this.content,
    required this.category,
    this.x = 0.0,
    this.y = 0.0,
    this.z = 0.0,
    this.frequency = 1.0,
    this.intensity = 1.0,
  }) {
    _clampCoordinates();
  }

  void _clampCoordinates() {
    x = x.clamp(-10.0, 10.0);
    y = y.clamp(-10.0, 10.0);
    z = z.clamp(-10.0, 10.0);
  }

  /// Távolság a középponti magtól (0, 0, 0)
  double get distanceFromCore => sqrt(x * x + y * y + z * z);

  /// Meghatározza, hogy az elem jelenleg melyik rétegben tartózkodik (1-36)
  int get currentLayer {
    final dist = distanceFromCore; // Max elméleti távolság ~17.32 (sqrt(300))
    final layer = (dist / 17.32 * 36).ceil();
    return layer.clamp(1, 36);
  }

  /// Rezgés és pozíció finomhangolása a szomszédos impulzusok alapján
  void pulse(double timeDelta) {
    final noise = sin(DateTime.now().millisecondsSinceEpoch * 0.001 * frequency) * 0.05;
    x = (x + noise).clamp(-10.0, 10.0);
    y = (y + noise).clamp(-10.0, 10.0);
    z = (z + noise).clamp(-10.0, 10.0);
  }
}

/// A belső Geneviève-gömb fő adatrekesze
class GeneviewSphere {
  final List<SphereLayer> layers = [];
  final Map<String, SphereNode> nodes = {};

  GeneviewSphere() {
    _initialize36Layers();
  }

  void _initialize36Layers() {
    const double maxRadius = 17.32; // sqrt(10^2 + 10^2 + 10^2)
    const double step = maxRadius / 36.0;

    for (int i = 1; i <= 36; i++) {
      layers.add(SphereLayer(
        index: i,
        label: 'Layer_$i',
        radiusRangeStart: (i - 1) * step,
        radiusRangeEnd: i * step,
      ));
    }
  }

  /// Új fogalom vagy tudáselem beillesztése a térbe
  void addNode({
    required String id,
    required String content,
    required String category,
    double x = 0.0,
    double y = 0.0,
    double z = 0.0,
  }) {
    nodes[id] = SphereNode(
      id: id,
      content: content,
      category: category,
      x: x,
      y: y,
      z: z,
    );
  }

  /// Lekéri a maghoz legközelebb álló, legrelevánsabb csomópontokat
  List<SphereNode> getNodesNearCore({int limit = 5}) {
    final list = nodes.values.toList();
    list.sort((a, b) => a.distanceFromCore.compareTo(b.distanceFromCore));
    return list.take(limit).toList();
  }

  /// Szimulációs léptetés: minden csomópont finom belső rezgést végez
  void tick() {
    for (final node in nodes.values) {
      node.pulse(0.1);
    }
  }
}