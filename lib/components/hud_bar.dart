import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Thanh HUD trên cùng màn hình với bo góc dưới.
class HUDBar extends RectangleComponent {
  final double radius;
  final Color color;

  HUDBar({
    required Vector2 size,
    required this.radius,
    required this.color,
    int priority = 0,
  }) : super(
          size: size,
          position: Vector2(0, 0),
          priority: priority,
          paint: Paint()..color = color,
        );

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndCorners(
      size.toRect(),
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
    canvas.drawRRect(rrect, paint);
  }
}
