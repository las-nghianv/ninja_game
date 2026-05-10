import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlusOneEffect extends TextComponent {
  double _lifeTime = 0;
  final double _maxLifeTime = 0.8;
  final double effectScale;
  
  PlusOneEffect({
    required Vector2 position,
    required double scale,
  })  : effectScale = scale,
        super(
          text: '+1',
          position: position,
          textRenderer: TextPaint(
            style: GoogleFonts.poppins(
              color: const Color(0xFFFFD700),
              fontSize: 36 * scale, // Chữ to hơn
              fontWeight: FontWeight.w900, // Chữ rất đậm
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;
    position.y -= dt * 70 * effectScale; 
    
    final progress = _lifeTime / _maxLifeTime;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    textRenderer = TextPaint(
      style: GoogleFonts.poppins(
        color: const Color(0xFFFFD700).withOpacity(opacity),
        fontSize: 36 * effectScale,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: Colors.black54.withOpacity(opacity),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
    
    if (_lifeTime > _maxLifeTime) {
      removeFromParent();
    }
  }
}
