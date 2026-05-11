import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../components/effects.dart';
import '../components/movie_box.dart';
import '../models/media_preview.dart';

/// Quản lý toàn bộ logic va chạm và hậu quả: mất mạng, thu coin, mở hộp bí mật.
class CollisionManager {
  final CollisionManagerContext ctx;
  CollisionManager(this.ctx);

  void checkCactusCollision() {
    if (ctx.isInvulnerable) return;

    final Rect dinoRect = Rect.fromLTWH(
      ctx.dinoPosition.x,
      ctx.dinoPosition.y,
      ctx.dinoSize.x,
      ctx.dinoSize.y,
    );

    for (final SpriteComponent cactus in List.of(ctx.cacti)) {
      final Rect cactusRect = Rect.fromLTWH(
        cactus.position.x,
        cactus.position.y,
        cactus.size.x,
        cactus.size.y,
      );
      if (dinoRect.overlaps(cactusRect)) {
        _spawnHitEffect(cactus.position, cactus.size);
        _loseLife();
        return;
      }
    }
  }

  void checkCoinCollision() {
    final Rect dinoRect = Rect.fromLTWH(
      ctx.dinoPosition.x,
      ctx.dinoPosition.y,
      ctx.dinoSize.x,
      ctx.dinoSize.y,
    );

    for (final SpriteComponent coin in List.of(ctx.coins)) {
      final Rect coinRect = Rect.fromLTWH(
        coin.position.x,
        coin.position.y,
        coin.size.x,
        coin.size.y,
      );
      if (dinoRect.overlaps(coinRect)) {
        ctx.coins.remove(coin);
        coin.removeFromParent();
        _collectCoin(coin.position);
      }
    }
  }

  void checkBoxCollision() {
    final Rect dinoRect = Rect.fromLTWH(
      ctx.dinoPosition.x,
      ctx.dinoPosition.y,
      ctx.dinoSize.x,
      ctx.dinoSize.y,
    );

    for (final box in List.of(ctx.boxes)) {
      final Rect boxRect = Rect.fromLTWH(
        box.position.x,
        box.position.y,
        box.size.x,
        box.size.y,
      );
      if (dinoRect.overlaps(boxRect)) {
        ctx.boxes.remove(box);
        box.removeFromParent();
        if (box is MovieBox) {
          _collectBox(box.movie);
        } else {
          _collectBox(null);
        }
      }
    }
  }

  void _collectCoin(Vector2 position) {
    ctx.coinPool.start(volume: 0.5);
    ctx.incrementCoin();
    final effect = PlusOneEffect(position: position.clone(), scale: ctx.scale);
    ctx.addComponent(effect);
  }

  void _collectBox(MediaPreview? movie) {
    FlameAudio.play('secre.wav', volume: 0.6);
    ctx.onBoxCollected(movie);
  }

  void _loseLife() {
    FlameAudio.play('bom.wav', volume: 0.6);
    ctx.decrementLife();
  }

  void _spawnHitEffect(Vector2 position, Vector2 size) {
    ctx.removeCurrentHitEffect();
    final double effectSize = math.max(size.x, size.y) * 2.8;
    final effect = SpriteComponent(
      sprite: ctx.hitSprite,
      size: Vector2.all(effectSize),
      position: Vector2(
        position.x + size.x / 2 - effectSize / 2,
        position.y + size.y / 2 - effectSize / 2,
      ),
    );
    ctx.setHitEffect(effect);
    ctx.addComponent(effect);
  }
}

/// Interface mô tả dữ liệu/callback mà CollisionManager cần từ game.
abstract class CollisionManagerContext {
  bool get isInvulnerable;
  double get scale;

  Vector2 get dinoPosition;
  Vector2 get dinoSize;

  Sprite get hitSprite;
  AudioPool get coinPool;

  List<SpriteComponent> get cacti;
  List<SpriteComponent> get coins;
  List<PositionComponent> get boxes;

  void addComponent(Component c);
  void incrementCoin();
  void decrementLife();
  void onBoxCollected(MediaPreview? movie);
  void removeCurrentHitEffect();
  void setHitEffect(SpriteComponent effect);
}
