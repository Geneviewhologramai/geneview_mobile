// ==============================================================================
// PONTOS HELY: lib/core/presence/hologram_3d_sphere.dart
// ==============================================================================

import 'package:flutter/material.dart';
import '../contracts/presence_contract.dart';

class Hologram3dSphere extends StatelessWidget {
  final PresenceState state;

  const Hologram3dSphere({
    super.key,
    this.state = PresenceState.idle,
  });

  @override
  Widget build(BuildContext context) {
    Color glowColor;
    switch (state) {
      case PresenceState.speaking:
        glowColor = const Color(0xFFD4AF37);
        break;
      case PresenceState.thinking:
        glowColor = Colors.cyanAccent;
        break;
      case PresenceState.error:
        glowColor = Colors.redAccent;
        break;
      case PresenceState.idle:
      default:
        glowColor = const Color(0xFF1E3A3A);
        break;
    }

    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withAlpha((0.4 * 255).round()),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: glowColor, width: 2),
        ),
        child: CustomPaint(
          painter: _SphereWireframePainter(color: glowColor),
        ),
      ),
    );
  }
}

class _SphereWireframePainter extends CustomPainter {
  final Color color;
  _SphereWireframePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha((0.3 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, paint);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius, height: radius * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}