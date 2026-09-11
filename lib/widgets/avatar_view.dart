import 'dart:math' as math;
import 'package:flutter/material.dart';

class AvatarView extends StatefulWidget {
  final bool isSpeaking;
  final bool isListening;
  final double baseBpm;

  const AvatarView({
    super.key,
    this.isSpeaking = false,
    this.isListening = false,
    this.baseBpm = 60.0,
  });

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> with TickerProviderStateMixin {
  late AnimationController _idleHeadController;
  late AnimationController _speechGestureController;

  @override
  void initState() {
    super.initState();

    _idleHeadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )..repeat();

    _speechGestureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.isSpeaking) {
      _speechGestureController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSpeaking && !_speechGestureController.isAnimating) {
      _speechGestureController.repeat(reverse: true);
    } else if (!widget.isSpeaking && _speechGestureController.isAnimating) {
      _speechGestureController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _idleHeadController.dispose();
    _speechGestureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final avatarHeight = isLandscape ? screenHeight * 0.68 : screenHeight * 0.74;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleHeadController,
        _speechGestureController,
      ]),
      builder: (context, child) {
        final idleT = _idleHeadController.value * 2 * math.pi;
        final gestureVal = _speechGestureController.value;

        // Finom fejmozgás és artikuláció
        final idleHeadRoll = math.sin(idleT) * 0.012;
        final speechNod = widget.isSpeaking
            ? (math.sin(gestureVal * math.pi * 2) * 0.025)
            : 0.0;
        final totalHeadAngle = idleHeadRoll + speechNod;

        // Foton-légzés pulzálás
        final chestBreath = 1.0 + (math.sin(idleT) * 0.009);

        return Center(
          child: SizedBox(
            height: avatarHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. RÉTEG: A FIZIKAI TALAPZAT (Art Deco Doboz)
                // 100% MOZDULATLAN
                ClipRect(
                  clipper: _BaseBoxClipper(),
                  child: Image.asset(
                    'assets/images/Geneview.png',
                    height: avatarHeight,
                    fit: BoxFit.contain,
                  ),
                ),

                // 2. RÉTEG: A VETÍTETT HOLOGRAM (Kizárólag a figura)
                // A doboz felett lebeg és finoman artikulál
                ClipRect(
                  clipper: _HologramFigureClipper(),
                  child: Transform.scale(
                    scale: chestBreath,
                    alignment: const Alignment(0, 0.55),
                    child: Transform.rotate(
                      angle: totalHeadAngle,
                      alignment: const Alignment(0, -0.45),
                      child: Image.asset(
                        'assets/images/Geneview.png',
                        height: avatarHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // 3. RÉTEG: Holografikus foton-aurafény
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.22),
                          radius: 0.50,
                          colors: [
                            widget.isSpeaking
                                ? const Color(0xFF00FFFF).withValues(alpha: 0.16)
                                : (widget.isListening
                                    ? const Color(0xFFFFD700).withValues(alpha: 0.14)
                                    : const Color(0xFF00E5FF).withValues(alpha: 0.04)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A fizikailag stabil talapzat (alsó ~25%) leválasztása
class _BaseBoxClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, size.height * 0.75, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// A kék hologram figura (felső ~75%) leválasztása
class _HologramFigureClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height * 0.75);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}