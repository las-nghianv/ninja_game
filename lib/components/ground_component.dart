import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TiledGroundComponent extends PositionComponent {
  TiledGroundComponent({
    required Sprite sprite,
    required super.size,
    required super.position,
  }) : _sprite = sprite;

  final Sprite _sprite;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Vector2 srcSize = _sprite.srcSize;
    final double scale = size.y / srcSize.y;
    final double tileWidth = srcSize.x * scale;
    final double tileHeight = size.y;

    double x = 0;
    while (x < size.x) {
      _sprite.render(
        canvas,
        position: Vector2(x, 0),
        size: Vector2(tileWidth, tileHeight),
      );
      x += tileWidth;
    }
  }
}
