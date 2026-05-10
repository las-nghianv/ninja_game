import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TiledStripComponent extends PositionComponent {
  TiledStripComponent({
    required Sprite sprite,
    required int tileCount,
    required double tileWidth,
    required super.size,
    required super.position,
  }) : _sprite = sprite,
       _tileCount = tileCount,
       _tileWidth = tileWidth;

  final Sprite _sprite;
  final int _tileCount;
  final double _tileWidth;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double tileHeight = size.y;

    for (int i = 0; i < _tileCount; i += 1) {
      _sprite.render(
        canvas,
        position: Vector2(_tileWidth * i, 0),
        size: Vector2(_tileWidth, tileHeight),
      );
    }
  }
}
