import 'dart:math' as math;

/// Hologram vetítési és mikromozgási transzformációs adatok
class HologramMeshTransform {
  final double chestExpansionScale;
  final double headTiltAngleDeg;
  final double eyeGazeDx;
  final double eyeGazeDy;
  final double hologramLuminescenceAlpha;
  final double verticalProjectionFloat;
  final bool isFrozenStatue;

  const HologramMeshTransform({
    required this.chestExpansionScale,
    required this.headTiltAngleDeg,
    required this.eyeGazeDx,
    required this.eyeGazeDy,
    required this.hologramLuminescenceAlpha,
    required this.verticalProjectionFloat,
    this.isFrozenStatue = false,
  });
}

/// ANTI-BÁBU TÉRBELI MIKROMOZGÁS MOTOR
/// A doboz szilárd talapzatként áll, a vetített kék entitás finoman pulzál
class LivingHologramMicroMotion {
  final double baseBpm;

  const LivingHologramMicroMotion({this.baseBpm = 60.0});

  /// Folyamatos organikus mikromozgás és foton-légzés
  HologramMeshTransform getLiveMeshTransform(double t) {
    // 1. Organikus légzési ritmus (finom, lassú mellkasmozgás)
    final breathCycle = math.sin(t * (baseBpm / 60.0) * 2 * math.pi);

    // 2. Fotonikus hullámzás (nem ugrál, csak a vetítési fény sűrűsége változik)
    final microFlicker = math.sin(t * 3.5) * 0.04;

    // 3. Nagyon enyhe testsúlyáthelyezés / fejbiccentés (szögmásodpercekben)
    final subtleSway = math.cos(t * 0.4) * 0.015;

    return HologramMeshTransform(
      // A mellkas diszkrét pulzálása légzéskor
      chestExpansionScale: 1.0 + (breathCycle * 0.018),
      
      // Finom fejmozgás, sosem merev bábu
      headTiltAngleDeg: subtleSway * 8.0,
      
      // Tekintet mikromozgás
      eyeGazeDx: subtleSway * 0.3,
      eyeGazeDy: breathCycle * 0.15,
      
      // A fényerő finom lélegzése (0.82 - 0.98 tartományban)
      hologramLuminescenceAlpha: (0.88 + (breathCycle * 0.08) + microFlicker).clamp(0.75, 1.0),
      
      // A vertikális lebegés minimálisra fogva (max 1.5 pixel), hogy ne rángassa a kompozíciót
      verticalProjectionFloat: math.sin(t * 1.2) * 1.5,
      
      isFrozenStatue: false,
    );
  }
}