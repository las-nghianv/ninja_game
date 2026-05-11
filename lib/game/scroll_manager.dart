import 'package:flame/components.dart';

import '../components/cloud_data.dart';
import '../components/strip_component.dart';

/// Manages the movement and removal of all scrolling objects on the screen.
class ScrollManager {
  final ScrollManagerContext ctx;
  ScrollManager(this.ctx);

  void updateObstacles(double dt) {
    for (final SpriteComponent cactus in List.of(ctx.cacti)) {
      cactus.position.x -= ctx.scrollSpeed * dt;
      if (cactus.position.x + cactus.size.x < -20) {
        ctx.cacti.remove(cactus);
        cactus.removeFromParent();
      }
    }
  }

  void updatePlatforms(double dt) {
    for (final TiledStripComponent platform in List.of(ctx.platforms)) {
      platform.position.x -= ctx.scrollSpeed * dt;
      if (platform.position.x + platform.size.x < -40) {
        ctx.platforms.remove(platform);
        platform.removeFromParent();
      }
    }
  }

  void updateCoins(double dt) {
    for (final SpriteComponent coin in List.of(ctx.coins)) {
      coin.position.x -= ctx.scrollSpeed * dt;
      if (coin.position.x + coin.size.x < -20) {
        ctx.coins.remove(coin);
        coin.removeFromParent();
      }
    }
  }

  void updateBoxes(double dt) {
    for (final box in List.of(ctx.boxes)) {
      box.position.x -= ctx.scrollSpeed * dt;
      if (box.position.x + box.size.x < -20) {
        ctx.boxes.remove(box);
        box.removeFromParent();
      }
    }
  }

  void updateClouds(double dt) {
    for (final SpriteComponent cloud in List.of(ctx.clouds)) {
      final data = cloud.children.query<CloudData>().firstOrNull;
      final multiplier = data?.speedMultiplier ?? 0.5;
      cloud.position.x -= (ctx.scrollSpeed * multiplier) * dt;
      if (cloud.position.x + cloud.size.x < -100) {
        ctx.clouds.remove(cloud);
        cloud.removeFromParent();
      }
    }
  }
}

/// Interface describing the data that ScrollManager needs from the game.
abstract class ScrollManagerContext {
  double get scrollSpeed;

  List<SpriteComponent> get cacti;
  List<SpriteComponent> get coins;
  List<SpriteComponent> get clouds;
  List<PositionComponent> get boxes;
  List<TiledStripComponent> get platforms;
}
