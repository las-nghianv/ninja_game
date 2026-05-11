import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../components/strip_component.dart';

/// Manages physics and character control: jumping, gravity, landing on ground/platforms.
class PlayerController {
  final PlayerControllerContext ctx;
  PlayerController(this.ctx);

  void jump() {
    if (isStandingOnSurface()) {
      ctx.jumpPool.start(volume: 0.5);
      ctx.setVelocityY(-ctx.jumpSpeed);
      ctx.onJumped();
    }
  }

  void update(double dt) {
    ctx.addVelocityY(ctx.gravity * dt);

    final Vector2 dinoPos = ctx.dinoPosition;
    final Vector2 dinoSz = ctx.dinoSize;

    final Rect currentRect = Rect.fromLTWH(
      dinoPos.x,
      dinoPos.y,
      dinoSz.x,
      dinoSz.y,
    );
    final Rect nextRect = Rect.fromLTWH(
      dinoPos.x,
      dinoPos.y + ctx.velocityY * dt,
      dinoSz.x,
      dinoSz.y,
    );

    final Rect groundRect = ctx.groundRect;
    double? landingTop;

    if (_isLandingOnSurface(currentRect, nextRect, groundRect)) {
      landingTop = groundRect.top;
    }

    for (final TiledStripComponent platform in ctx.platforms) {
      final Rect platformRect = Rect.fromLTWH(
        platform.position.x,
        platform.position.y,
        platform.size.x,
        platform.size.y,
      );
      if (_isLandingOnSurface(currentRect, nextRect, platformRect)) {
        if (landingTop == null || platformRect.top < landingTop) {
          landingTop = platformRect.top;
        }
      }
    }

    if (landingTop != null) {
      ctx.setDinoY(landingTop - dinoSz.y);
      ctx.setVelocityY(0);
    } else {
      ctx.setDinoY(dinoPos.y + ctx.velocityY * dt);
    }
  }

  bool isStandingOnSurface() {
    if (ctx.velocityY.abs() > 0.1) return false;

    final Rect dinoRect = Rect.fromLTWH(
      ctx.dinoPosition.x,
      ctx.dinoPosition.y,
      ctx.dinoSize.x,
      ctx.dinoSize.y,
    );

    if ((dinoRect.bottom - ctx.groundRect.top).abs() < 0.5) return true;

    for (final TiledStripComponent platform in ctx.platforms) {
      final Rect platformRect = Rect.fromLTWH(
        platform.position.x,
        platform.position.y,
        platform.size.x,
        platform.size.y,
      );
      if ((dinoRect.bottom - platformRect.top).abs() < 0.5 &&
          dinoRect.right > platformRect.left &&
          dinoRect.left < platformRect.right) {
        return true;
      }
    }
    return false;
  }

  bool _isLandingOnSurface(Rect current, Rect next, Rect surface) {
    if (current.bottom > surface.top) return false;
    final bool isFalling = next.bottom >= surface.top;
    final bool overlapsX =
        next.right > surface.left && next.left < surface.right;
    return isFalling && overlapsX;
  }
}

/// Interface describing the data/callbacks that PlayerController needs from the game.
abstract class PlayerControllerContext {
  double get gravity;
  double get jumpSpeed;
  double get velocityY;
  AudioPool get jumpPool;

  Vector2 get dinoPosition;
  Vector2 get dinoSize;
  Rect get groundRect;
  List<TiledStripComponent> get platforms;

  void setVelocityY(double v);
  void addVelocityY(double delta);
  void setDinoY(double y);
  void onJumped();
}
