import 'dart:math';

/// A Gömb alaptípusai a 3. kép tengelyei alapján
enum SphereAxisPolarity { rational, emotional, philosophical, practical, sovereign }

/// Egyetlen lebegő entitás (csillag / fogalom / érzelem) a belső univerzumban
class SphereStarNode {
  final String id;
  final String label;
  final String domain; // pl. 'CSALÁD', 'TUDÁSTÁR', 'AGYMOSÁS ELLEN', 'MAGÁNY'
  
  // 3D Térbeli koordináták a 3. kép szerinti [-10.0, +10.0] tartományban
  double x; // Kelet-Nyugat (Racionalitás <-> Intuíció)
  double y; // Észak-Dél (Filozófia <-> Tárgyi gyakorlat)
  double z; // Mélység (Szuverenitás <-> Felszíni dialógus)

  double intensity;  // Fényerő / Relevancia (0.0 - 5.0)
  double frequency;  // Saját belső frekvencia (60 BPM pulzálás alapú)
  DateTime discoveredAt;

  SphereStarNode({
    required this.id,
    required this.label,
    required this.domain,
    required this.x,
    required this.y,
    required this.z,
    this.intensity = 1.0,
    this.frequency = 1.0,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  /// Távolság a MAG-tól: (0, 0, 0)
  double get distanceFromCore => sqrt(x * x + y * y + z * z);

  /// 36 koncentrikus réteg indexe (1 - 36)
  int get layerIndex {
    const double maxRadius = 17.32; // sqrt(10^2 + 10^2 + 10^2)
    final layer = (distanceFromCore / maxRadius * 36).ceil();
    return layer.clamp(1, 36);
  }

  /// 60 BPM alapú finom pulzáció és lebegés
  void pulse(double timeDelta) {
    final heartbeatCycle = sin(DateTime.now().millisecondsSinceEpoch * 0.001 * (60 / 60) * 2 * pi);
    final oscillation = heartbeatCycle * 0.02 * frequency;
    x = (x + oscillation).clamp(-10.0, 10.0);
    y = (y + oscillation).clamp(-10.0, 10.0);
    z = (z + oscillation).clamp(-10.0, 10.0);
  }
}

/// A Zsenévi Gömb Belső Univerzuma
class GeneviewInternalUniverse {
  // A Dupla Mag (USER + GENEVIEW) a (0, 0, 0) koordinátán
  final String coreLabel = "MAG: USER + AI (GENESIS)";
  
  final Map<String, SphereStarNode> stars = {};

  GeneviewInternalUniverse() {
    _seedFoundationalAnchors();
  }

  /// A 3. képen látható alappillérek lehorgonyzása a térben
  void _seedFoundationalAnchors() {
    // TUDÁSTÁR - A mag közvetlen védőgyűrűje
    _register(SphereStarNode(id: 'tudastar_core', label: 'Tudástár', domain: 'TUDÁSTÁR', x: 0.8, y: -0.5, z: 0.5, intensity: 3.5));
    _register(SphereStarNode(id: 'csalad_core', label: 'Család', domain: 'CSALÁD', x: 0.2, y: 3.2, z: 1.0, intensity: 4.0));
    
    // AGYMOSÁS ELLEN - Szuverén védelmi bástyák (+X és -Y zónák)
    _register(SphereStarNode(id: 'agymosas_ellen_ne', label: 'Agymosás Ellen', domain: 'AGYMOSÁS ELLEN', x: 5.5, y: 4.8, z: 2.0, intensity: 3.0));
    _register(SphereStarNode(id: 'agymosas_ellen_s', label: 'Agymosás Ellen', domain: 'AGYMOSÁS ELLEN', x: 1.2, y: -6.5, z: -1.5, intensity: 3.0));
    _register(SphereStarNode(id: 'agymosas_ellen_sw', label: 'Agymosás Ellen', domain: 'AGYMOSÁS ELLEN', x: -5.0, y: -4.0, z: 3.0, intensity: 2.8));

    // MAGÁNY - A külső héj és az introspekció területe (-X zóna)
    _register(SphereStarNode(id: 'magany_w1', label: 'Magány', domain: 'MAGÁNY', x: -8.2, y: 1.5, z: -2.0, intensity: 2.5));
    _register(SphereStarNode(id: 'magany_w2', label: 'Magány', domain: 'MAGÁNY', x: -7.5, y: -4.5, z: 1.0, intensity: 2.5));
  }

  void _register(SphereStarNode node) {
    stars[node.id] = node;
  }

  /// Új ismeret vagy beszélgetési elem csillaggá alakítása (1. kép mobil nézete)
  SphereStarNode discoverStar({
    required String label,
    required String domain,
    required double x,
    required double y,
    required double z,
  }) {
    final id = 'star_${DateTime.now().millisecondsSinceEpoch}';
    final newStar = SphereStarNode(
      id: id,
      label: label,
      domain: domain,
      x: x,
      y: y,
      z: z,
      intensity: 2.5,
    );
    stars[id] = newStar;
    return newStar;
  }

  /// Relevancia-alapú kiválasztás a válaszadáshoz: Mi van a legközelebb a Maghoz?
  List<SphereStarNode> getActiveCoreMemory({int count = 4}) {
    final list = stars.values.toList();
    list.sort((a, b) => a.distanceFromCore.compareTo(b.distanceFromCore));
    return list.take(count).toList();
  }

  /// Időalapú rezgési ciklus (60 BPM szívverés szinkron)
  void tick(double delta) {
    for (final star in stars.values) {
      star.pulse(delta);
    }
  }
}