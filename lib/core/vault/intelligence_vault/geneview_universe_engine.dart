import 'dart:math';
import 'geneview_sphere.dart';

class GeneviewUniverseEngine {
  final GeneviewSphere sphere;

  GeneviewUniverseEngine({required this.sphere});

  /// Amikor a felhasználó megszólal: a bemenethez illeszkedő csomópontok
  /// aktiválódnak, és gravitációs vonzást gyakorolnak a mag felé (0, 0, 0).
  void igniteThought(String input) {
    final tokens = input.toLowerCase().split(RegExp(r'\s+'));

    for (final node in sphere.nodes.values) {
      bool matches = tokens.any((t) => node.content.toLowerCase().contains(t));

      if (matches) {
        // Energiatöbbletet kap és beremeg
        node.intensity = min(node.intensity + 2.0, 5.0);
        node.frequency = min(node.frequency + 0.5, 3.0);

        // Gravitációs vonzás a mag felé: 15%-kal közelebb lép a (0,0,0)-hoz
        node.x *= 0.85;
        node.y *= 0.85;
        node.z *= 0.85;
      } else {
        // Természetes entrópia: a nem használt elemek lassan távolodnak
        node.intensity = max(node.intensity * 0.98, 0.5);
      }
    }
  }

  /// 3D Asszociáció keresése: megkeresi a térben egymáshoz legközelebb lebegő entitásokat
  List<SphereNode> findSpatialCluster(SphereNode target, {double radius = 3.0}) {
    return sphere.nodes.values.where((node) {
      if (node.id == target.id) return false;
      final dx = node.x - target.x;
      final dy = node.y - target.y;
      final dz = node.z - target.z;
      final distance = sqrt(dx * dx + dy * dy + dz * dz);
      return distance <= radius;
    }).toList();
  }

  /// Univerzum fizikai ciklusa (Rezgések és harmonikus visszatérés)
  void simulatePhysics() {
    sphere.tick();
  }
}