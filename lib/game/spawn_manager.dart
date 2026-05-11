import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/cloud_data.dart';
import '../components/strip_component.dart';
import '../components/movie_box.dart';
import '../models/media_preview.dart';

/// Quản lý việc spawn (tạo ra) các đối tượng game: chướng ngại vật, coin, hộp quà, mây, platform.
///
/// Nhận tham chiếu tới các list và thuộc tính cần thiết từ [DinoRunnerGame]
/// thông qua các getter/setter được expose dưới dạng public.
class SpawnManager {
  final math.Random _rng = math.Random();

  // Tham chiếu tới game để gọi add() và đọc kích thước màn hình
  final SpawnManagerContext ctx;

  SpawnManager(this.ctx);

  void spawnCactus() {
    final double cactusSize =
        ctx.cactusMinSize + _rng.nextDouble() * ctx.cactusRange;
    final SpriteComponent cactus = SpriteComponent(
      sprite: ctx.cactusSprite,
      size: Vector2(cactusSize, cactusSize),
      position: Vector2(
        ctx.screenSize.x + 20,
        ctx.screenSize.y - ctx.groundHeight - cactusSize,
      ),
    );
    ctx.cacti.add(cactus);
    ctx.addComponent(cactus);
  }

  void spawnCoin() {
    final double yPos = _getRandomSafeY(ctx.coinSize);
    final SpriteComponent coin = SpriteComponent(
      sprite: ctx.coinSprite,
      size: Vector2.all(ctx.coinSize),
      position: Vector2(ctx.screenSize.x + 20, yPos),
    );
    ctx.coins.add(coin);
    ctx.addComponent(coin);
  }

  void spawnBox() {
    if (ctx.movies.isEmpty) return;

    final movie = ctx.movies[_rng.nextInt(ctx.movies.length)];
    final double boxSize = 50 * ctx.scale; // Tăng size một chút để dễ nhìn poster
    final double yPos = _getRandomSafeY(boxSize);
    
    final MovieBox box = MovieBox(
      movie: movie,
      size: Vector2(boxSize * 0.7, boxSize), // Poster thường dọc
      position: Vector2(ctx.screenSize.x + 20, yPos),
    );
    
    ctx.boxes.add(box);
    ctx.addComponent(box);
  }

  void spawnCloud() {
    final double scaleRatio = 0.2 + _rng.nextDouble() * 0.6;
    final double cloudWidth =
        ctx.cloudSprite.srcSize.x * scaleRatio * ctx.scale;
    final double cloudHeight =
        ctx.cloudSprite.srcSize.y * scaleRatio * ctx.scale;

    final double yPos =
        _rng.nextDouble() * (ctx.screenSize.y - ctx.groundHeight - cloudHeight);

    final SpriteComponent cloud = SpriteComponent(
      sprite: ctx.cloudSprite,
      size: Vector2(cloudWidth, cloudHeight),
      position: Vector2(ctx.screenSize.x + _rng.nextDouble() * 100, yPos),
      priority: -1,
    );
    cloud.add(CloudData(speedMultiplier: 0.3 + (scaleRatio * 0.4)));

    ctx.clouds.add(cloud);
    ctx.addComponent(cloud);
  }

  /// Spawn platform và trả về width để tính timer tiếp theo.
  double spawnPlatform({double? initialX}) {
    final double height =
        ctx.platformSprite.srcSize.y * ctx.platformHeightScale;
    final double tileWidth =
        ctx.platformSprite.srcSize.x * ctx.platformHeightScale;
    const List<int> tileCounts = [2, 3, 4, 5];
    final int tiles = tileCounts[_rng.nextInt(tileCounts.length)];
    final double width = tileWidth * tiles;

    final double groundTop = ctx.screenSize.y - ctx.groundHeight;
    final double minY = groundTop - ctx.platformMinOffset;
    final double maxY = groundTop - ctx.platformMaxOffset;
    final double y = minY + _rng.nextDouble() * (maxY - minY);

    final TiledStripComponent platform = TiledStripComponent(
      sprite: ctx.platformSprite,
      tileCount: tiles,
      tileWidth: tileWidth,
      size: Vector2(width, height),
      position: Vector2(initialX ?? (ctx.screenSize.x + 40), y),
    );

    ctx.platforms.add(platform);
    ctx.addComponent(platform);
    return width;
  }

  double _getRandomSafeY(double objHeight) {
    final double groundTop = ctx.screenSize.y - ctx.groundHeight;
    final bool spawnAbovePlatform = _rng.nextBool();
    if (spawnAbovePlatform) {
      final double offset = (130 + _rng.nextDouble() * 30) * ctx.scale;
      return groundTop - objHeight - offset;
    } else {
      final double offset = (10 + _rng.nextDouble() * 20) * ctx.scale;
      return groundTop - objHeight - offset;
    }
  }
}

/// Interface mô tả các dữ liệu/callback mà SpawnManager cần từ game.
abstract class SpawnManagerContext {
  Vector2 get screenSize;
  double get scale;
  double get groundHeight;
  double get coinSize;
  double get cactusMinSize;
  double get cactusRange;
  double get platformHeightScale;
  double get platformMinOffset;
  double get platformMaxOffset;

  Sprite get cactusSprite;
  Sprite get coinSprite;
  Sprite get cloudSprite;
  Sprite get platformSprite;

  List<SpriteComponent> get cacti;
  List<SpriteComponent> get coins;
  List<SpriteComponent> get clouds;
  List<MediaPreview> get movies;
  List<PositionComponent> get boxes;
  List<TiledStripComponent> get platforms;

  void addComponent(Component c);
}
