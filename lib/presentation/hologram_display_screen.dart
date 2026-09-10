import 'dart:math' as math;
import 'package:flutter/material.dart';

enum HologramProjectionMode {
  standard, // Sima frontális 2D/3D nézet
  pyramid,  // 4-oldalas fizikai piramis mód (Pepper's Ghost optika)
  prism,    // Kettős / prizmás vetítés
}

class HologramDisplayScreen extends StatefulWidget {
  final String activeFrame;
  final bool isSpeaking;

  const HologramDisplayScreen({
    super.key,
    required this.activeFrame,
    this.isSpeaking = false,
  });

  @override
  State<HologramDisplayScreen> createState() => _HologramDisplayScreenState();
}

class _HologramDisplayScreenState extends State<HologramDisplayScreen> {
  HologramProjectionMode _currentMode = HologramProjectionMode.pyramid;

  Widget _buildAvatarFigure() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeInOut,
      child: Image.asset(
        widget.activeFrame,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/Geneview.png', fit: BoxFit.contain);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Koromfekete a tükröződésmentes hologramhoz
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _buildProjectionContent(),
              ),
            ),
            _buildModeSelectorBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionContent() {
    switch (_currentMode) {
      case HologramProjectionMode.pyramid:
        return _buildPyramidQuadView();
      case HologramProjectionMode.prism:
        return _buildPrismDualView();
      case HologramProjectionMode.standard:
      default:
        return Center(
          child: SizedBox(
            width: 280,
            height: 380,
            child: _buildAvatarFigure(),
          ),
        );
    }
  }

  // 4-oldalas piramis elrendezés (Fel, Le, Balra, Jobbra forgatva a 4 üveglaphoz)
  Widget _buildPyramidQuadView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.biggest.shortestSide * 0.38;

        return SizedBox(
          width: constraints.biggest.shortestSide,
          height: constraints.biggest.shortestSide,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Középső kalibrációs pont a piramis csúcsának helyéhez
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),

              // 1. Felső vetület (180 fokban fejjel lefelé)
              Positioned(
                top: 0,
                child: Transform.rotate(
                  angle: math.pi,
                  child: SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: _buildAvatarFigure(),
                  ),
                ),
              ),

              // 2. Alsó vetület (normál állásban)
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: _buildAvatarFigure(),
                ),
              ),

              // 3. Bal oldali vetület (90 fok jobbra forgatva)
              Positioned(
                left: 0,
                child: Transform.rotate(
                  angle: math.pi / 2,
                  child: SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: _buildAvatarFigure(),
                  ),
                ),
              ),

              // 4. Jobb oldali vetület (90 fok balra forgatva)
              Positioned(
                right: 0,
                child: Transform.rotate(
                  angle: -math.pi / 2,
                  child: SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: _buildAvatarFigure(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Kettős prizma nézet
  Widget _buildPrismDualView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildAvatarFigure()),
        Expanded(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(math.pi),
            child: _buildAvatarFigure(),
          ),
        ),
      ],
    );
  }

  // Alsó üzemmódváltó sáv
  Widget _buildModeSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        border: Border(
          top: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildModeButton(
            title: 'STANDARD',
            mode: HologramProjectionMode.standard,
            icon: Icons.crop_portrait,
          ),
          _buildModeButton(
            title: 'PYRAMID 4X',
            mode: HologramProjectionMode.pyramid,
            icon: Icons.change_history,
          ),
          _buildModeButton(
            title: 'PRISM SPLIT',
            mode: HologramProjectionMode.prism,
            icon: Icons.view_column_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required HologramProjectionMode mode,
    required IconData icon,
  }) {
    final isSelected = _currentMode == mode;
    return InkWell(
      onTap: () => setState(() => _currentMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.cyanAccent : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}