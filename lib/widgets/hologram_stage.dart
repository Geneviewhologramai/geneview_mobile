import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/art_deco_theme.dart';
import '../services/box_bridge_service.dart';

enum ProjectionMode {
  screen,      // Hétköznapi közvetlen képernyőmód
  pyramid360,  // 4-oldalas 360°-os akril piramis vetület
  theaterBox,  // Egyoldalas zárt tükrözött doboz
}

class HologramStage extends StatefulWidget {
  final ProjectionMode mode;
  final Widget avatarWidget;

  const HologramStage({
    super.key,
    required this.mode,
    required this.avatarWidget,
  });

  @override
  State<HologramStage> createState() => _HologramStageState();
}

class _HologramStageState extends State<HologramStage> {
  final BoxBridgeService _bridgeService = BoxBridgeService();
  bool _isCommunicating = false;

  Future<void> sendTelemetry({
    required double valence,
    required double arousal,
  }) async {
    setState(() => _isCommunicating = true);
    final response = await _bridgeService.sendEmotionalTelemetry(
      valence: valence,
      arousal: arousal,
    );
    if (mounted) {
      setState(() => _isCommunicating = false);
    }
    if (response != null) {
      debugPrint('[HologramStage] Szinkron sikeres: ${response.pulseFrequencyHz} Hz, Színhő: ${response.colorTempKelvin}K');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case ProjectionMode.screen:
        return _buildScreenMode();
      case ProjectionMode.theaterBox:
        return _buildTheaterBoxMode();
      case ProjectionMode.pyramid360:
        return _buildPyramid360Mode();
    }
  }

  Widget _buildScreenMode() {
    return Container(
      color: Colors.black,
      child: Center(
        child: widget.avatarWidget,
      ),
    );
  }

  Widget _buildTheaterBoxMode() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(1.0, -1.0, 1.0),
          child: widget.avatarWidget,
        ),
      ),
    );
  }

  Widget _buildPyramid360Mode() {
    return Container(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, constraints.maxHeight);
          final facetSize = size * 0.38;

          return Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Észak (Felül)
                  Positioned(
                    top: 0,
                    child: SizedBox(
                      width: facetSize,
                      height: facetSize,
                      child: widget.avatarWidget,
                    ),
                  ),

                  // Dél (Alul)
                  Positioned(
                    bottom: 0,
                    child: SizedBox(
                      width: facetSize,
                      height: facetSize,
                      child: Transform.rotate(
                        angle: math.pi,
                        child: widget.avatarWidget,
                      ),
                    ),
                  ),

                  // Nyugat (Balra)
                  Positioned(
                    left: 0,
                    child: SizedBox(
                      width: facetSize,
                      height: facetSize,
                      child: Transform.rotate(
                        angle: math.pi / 2,
                        child: widget.avatarWidget,
                      ),
                    ),
                  ),

                  // Kelet (Jobbra)
                  Positioned(
                    right: 0,
                    child: SizedBox(
                      width: facetSize,
                      height: facetSize,
                      child: Transform.rotate(
                        angle: -math.pi / 2,
                        child: widget.avatarWidget,
                      ),
                    ),
                  ),

                  // Központi akril maszkoló négyzet
                  Container(
                    width: size * 0.24,
                    height: size * 0.24,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(
                        color: ArtDecoTheme.goldAccent.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCommunicating
                              ? ArtDecoTheme.goldAccent
                              : ArtDecoTheme.goldAccent.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}