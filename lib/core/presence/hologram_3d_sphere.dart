import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:geneview_mobile/core/contracts/i_presence_vault.dart';

class Hologram3DSphere extends StatefulWidget {
  final PresenceState state;

  const Hologram3DSphere({super.key, required this.state});

  @override
  State<Hologram3DSphere> createState() => _Hologram3DSphereState();
}

class _Hologram3DSphereState extends State<Hologram3DSphere>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Folyamatos 3D tengely körüli lebegő forgás
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Pulzálás a hang és gondolkodás ütemére
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Állapothoz rendelt holografikus szín és intenzitás
  (Color, double) _getVisualParams() {
    switch (widget.state) {
      case PresenceState.speaking:
        return (const Color(0xFF00F0FF), 1.6); // Vibráló holografikus cián
      case PresenceState.thinking:
        return (const Color(0xFFB026FF), 1.3); // Neon lila pulzálás
      case PresenceState.listening:
        return (const Color(0xFF00FFA3), 1.2); // Halvány smaragdzöld
      case PresenceState.idle:
      default:
        return (const Color(0xFF3A86FF), 0.7); // Nyugodt kék lebegés
    }
  }

  @override
  Widget build(BuildContext context) {
    final (baseColor, energy) = _getVisualParams();

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          final pulse = _pulseController.value;
          final angle = _rotationController.value * 2 * math.pi;

          return SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Réteg: Háttér mélységi glória (Glow Aura)
                Container(
                  width: 240 + (pulse * 30 * energy),
                  height: 240 + (pulse * 30 * energy),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.25 * energy),
                        blurRadius: 60 + (pulse * 40),
                        spreadRadius: 10 + (pulse * 15),
                      ),
                    ],
                  ),
                ),

                // 2. Réteg: 3D Döntött perspektivikus giroszkóp gyűrűk
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // 3D mélységi perspektíva
                    ..rotateX(0.55 + (pulse * 0.1))
                    ..rotateY(angle),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: baseColor.withValues(alpha: 0.7),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),

                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(-0.4)
                    ..rotateZ(angle * 1.3),
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: baseColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),

                // 3. Réteg: 3D Pont- és Részecskefelhő Mag (CustomPainter)
                CustomPaint(
                  size: const Size(260, 260),
                  painter: _HolographicSpherePainter(
                    angle: angle,
                    pulse: pulse,
                    energy: energy,
                    color: baseColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HolographicSpherePainter extends CustomPainter {
  final double angle;
  final double pulse;
  final double energy;
  final Color color;

  _HolographicSpherePainter({
    required this.angle,
    required this.pulse,
    required this.energy,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 80.0 + (pulse * 8.0 * energy);

    final dotPaint = Paint()..style = PaintingStyle.fill;

    const int rings = 14;
    const int dotsPerRing = 24;

    // 3D gömbfelszíni pontok leképezése 2D vetületre
    for (int i = 0; i < rings; i++) {
      final phi = (math.pi / (rings + 1)) * (i + 1);
      final y = baseRadius * math.cos(phi);
      final ringRadius = baseRadius * math.sin(phi);

      for (int j = 0; j < dotsPerRing; j++) {
        final theta = (2 * math.pi / dotsPerRing) * j + angle;
        final x = ringRadius * math.cos(theta);
        final z = ringRadius * math.sin(theta); // 3D mélység (Z-tengely)

        // Mélység alapú méret és átlátszóság (ami közelebb van, az nagyobb és fényesebb)
        final depthNorm = (z + baseRadius) / (2 * baseRadius); // 0.0 (hátul) - 1.0 (elöl)
        final pointSize = 1.0 + (depthNorm * 2.5 * energy);
        final pointAlpha = (0.15 + (depthNorm * 0.75)).clamp(0.0, 1.0);

        dotPaint.color = color.withValues(alpha: pointAlpha);

        // Scanline effekt: finom pásztázó vonal hatás
        final projectedY = center.dy + y;
        final projectedX = center.dx + x;

        canvas.drawCircle(Offset(projectedX, projectedY), pointSize, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HolographicSpherePainter oldDelegate) => true;
}