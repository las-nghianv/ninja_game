// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'components/effects.dart';
import 'components/ground_component.dart';
import 'components/strip_component.dart';
import 'const/game_constants.dart';
import 'models/media_preview.dart';

class DinoRunnerGame extends FlameGame {
  late final TiledGroundComponent _ground;
  late final SpriteComponent _dino;
  late final Sprite _cactusSprite;
  late final Sprite _hitSprite;
  late final Sprite _platformSprite;
  late final Sprite _coinSprite;
  late final Sprite _cloudSprite;
  late final TextComponent _statusText;
  late final TextComponent _coinText;
  late final SpriteComponent _coinIcon;
  late AudioPool _jumpPool;
  late AudioPool _coinPool;

  Vector2 _dinoSize = Vector2(
    GameConstants.baseDinoWidth,
    GameConstants.baseDinoHeight,
  );
  Vector2 _velocity = Vector2.zero();
  double _obstacleTimer = 0;
  double _platformTimer = 0;
  double _coinTimer = 0;
  double _boxTimer = 0;
  double _cloudTimer = 0;
  int _coinCount = 0;
  int get coinCount => _coinCount;
  int _lives = 3;
  bool _isRunning = true;
  bool _isInvulnerable = false;
  double _invulnerableTimer = 0;
  double _hitTimer = 0;
  SpriteComponent? _hitEffect;

  double _scale = 1.0;
  final List<TextComponent> _hearts = [];
  final List<RectangleComponent> _boxes = [];
  List<MediaPreview> movies = [];
  MediaPreview? currentMovie;

  double _gravity = GameConstants.baseGravity;
  double _jumpSpeed = GameConstants.baseJumpSpeed;
  double _groundHeight = GameConstants.baseGroundHeight;
  double _scrollSpeed = GameConstants.baseScrollSpeed;
  double _platformHeightScale = GameConstants.basePlatformHeightScale;
  double _platformMinOffset = GameConstants.basePlatformMinOffset;
  double _platformMaxOffset = GameConstants.basePlatformMaxOffset;
  double _cactusMinSize = GameConstants.baseCactusMin;
  double _cactusRange = GameConstants.baseCactusRange;
  double _coinSize = GameConstants.baseCoinSize;

  final List<SpriteComponent> _cacti = [];
  final List<SpriteComponent> _coins = [];
  final List<SpriteComponent> _clouds = [];
  final List<TiledStripComponent> _platforms = [];
  final math.Random _rng = math.Random();

  @override
  Color backgroundColor() => const Color(0xFFB3E5FC);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await FlameAudio.audioCache.loadAll(['bom.wav', 'secre.wav']);

    _jumpPool = await FlameAudio.createPool('jump.wav', maxPlayers: 3);
    _coinPool = await FlameAudio.createPool('coin.wav', maxPlayers: 4);

    _applyScale();

    final groundImage = await images.load('Frame 60.png');
    _ground = TiledGroundComponent(
      sprite: Sprite(groundImage),
      size: Vector2(size.x, _groundHeight),
      position: Vector2(0, size.y - _groundHeight),
    );

    final image = await images.load('nhan_vat.png');
    _dino = SpriteComponent(
      sprite: Sprite(image),
      size: _dinoSize,
      position: Vector2(60 * _scale, size.y - _groundHeight - _dinoSize.y),
    );

    _cactusSprite = Sprite(await images.load('Group 25.png'));
    _hitSprite = Sprite(await images.load('Group 27.png'));
    _platformSprite = Sprite(await images.load('Frame 59.png'));
    _coinSprite = Sprite(await images.load('coin.png'));
    _cloudSprite = Sprite(await images.load('cloud.png'));

    // Tạo thanh HUD (AppBar) ở trên cùng với chiều cao 10% màn hình và bo góc dưới
    final double hudHeight = size.y * 0.1;
    // Sử dụng class HUDBar tùy chỉnh để hỗ trợ bo góc
    final hudBar = HUDBar(
      size: Vector2(size.x, hudHeight),
      radius: 2 * _scale,
      color: const Color(0xFF88DBEF),
      priority: 10,
    );
    add(hudBar);

    _coinIcon = SpriteComponent(
      sprite: _coinSprite,
      size: Vector2.all(_coinSize),
      // Đặt vị trí ở sát đáy thanh HUD
      position: Vector2(12 * _scale, hudHeight - _coinSize - 4 * _scale),
      priority: 11,
    );

    _coinText = TextComponent(
      text: '0',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 18 * _scale,
          fontWeight: FontWeight.w700,
        ),
      ),
      // Căn chỉnh Text theo dòng với Icon xu
      position: Vector2(40 * _scale, hudHeight - (18 * _scale) - 6 * _scale),
      priority: 11,
    );

    _statusText = TextComponent(
      text: 'Tap jump to start!',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14 * _scale,
          fontWeight: FontWeight.w500,
        ),
      ),
      position: Vector2(12 * _scale, 64 * _scale),
    );

    addAll([_ground, _dino, _statusText, _coinIcon, _coinText]);
    _createHearts();

    final double w1 = _spawnPlatform(initialX: size.x * 0.55);
    _spawnPlatform(
      initialX: math.max(size.x * 0.9, size.x * 0.55 + w1 + 40 * _scale),
    );
  }

  void _createHearts() {
    final double hudHeight = size.y * 0.05;
    for (int i = 0; i < _lives; i++) {
      final heart = TextComponent(
        text: '❤️',
        textRenderer: TextPaint(style: TextStyle(fontSize: 24 * _scale)),
        // Căn lề phải và đặt sát đáy thanh HUD
        position: Vector2(
          size.x - (36 * _scale * (i + 1)),
          hudHeight - (24 * _scale) - 4 * _scale,
        ),
        priority: 11,
      );
      _hearts.add(heart);
      add(heart);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    _applyScale();
    if (isLoaded) {
      _ground.size = Vector2(size.x, _groundHeight);
      _ground.position = Vector2(0, size.y - _groundHeight);
      _dino.size = _dinoSize;
      final double groundTop = size.y - _groundHeight;
      if (_dino.position.y > groundTop - _dinoSize.y) {
        _dino.position.y = groundTop - _dinoSize.y;
      }
      final double topPadding = size.y * 0.05;
      _coinIcon.size = Vector2.all(_coinSize);
      _coinIcon.position = Vector2(12 * _scale, topPadding);
      _coinText.position = Vector2(40 * _scale, topPadding + 2 * _scale);

      for (int i = 0; i < _hearts.length; i++) {
        _hearts[i].position = Vector2(
          size.x - (30 * _scale) * (i + 1) - 10 * _scale,
          topPadding,
        );
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_hitTimer > 0) {
      _hitTimer -= dt;
      if (_hitTimer <= 0) {
        _hitEffect?.removeFromParent();
        _hitEffect = null;
      }
    }

    if (_isInvulnerable) {
      _invulnerableTimer -= dt;
      final bool isVisible = (_invulnerableTimer * 10).toInt() % 2 == 0;
      _dino.paint.color = Colors.white.withOpacity(isVisible ? 1.0 : 0.5);

      if (_invulnerableTimer <= 0) {
        _isInvulnerable = false;
        _dino.paint.color = Colors.white.withOpacity(1.0);
      }
    }

    if (!_isRunning) {
      return;
    }

    _obstacleTimer -= dt;
    if (_obstacleTimer <= 0) {
      _spawnCactus();
      _obstacleTimer = 1.1 + _rng.nextDouble();
    }

    _platformTimer -= dt;
    if (_platformTimer <= 0) {
      final double width = _spawnPlatform();
      final double minTime = (width + 60 * _scale) / _scrollSpeed;
      _platformTimer = minTime + _rng.nextDouble() * 1.5;
    }

    _coinTimer -= dt;
    if (_coinTimer <= 0) {
      _spawnCoin();
      _coinTimer = 0.15 + _rng.nextDouble() * 0.3;
    }

    _boxTimer -= dt;
    if (_boxTimer <= 0) {
      _spawnBox();
      _boxTimer = 4.0 + _rng.nextDouble() * 4.0; // Xuất hiện sau mỗi 4-8 giây
    }

    _cloudTimer -= dt;
    if (_cloudTimer <= 0) {
      _spawnCloud();
      // Sinh mây thường xuyên hơn (mỗi 1-3 giây)
      _cloudTimer = 1.0 + _rng.nextDouble() * 2.0;
    }

    _updatePlatforms(dt);
    _updateObstacles(dt);
    _updateCoins(dt);
    _updateBoxes(dt);
    _updateClouds(dt);
    _updatePlayer(dt);
    _checkCactusCollision();
    _checkCoinCollision();
    _checkBoxCollision();
  }

  void jump() {
    if (!_isRunning) {
      return;
    }

    if (_isStandingOnSurface()) {
      _jumpPool.start(volume: 0.5);
      _velocity.y = -_jumpSpeed;
      _statusText.text = '';
    }
  }

  void _spawnCactus() {
    final double cactusSize = _cactusMinSize + _rng.nextDouble() * _cactusRange;
    final SpriteComponent cactus = SpriteComponent(
      sprite: _cactusSprite,
      size: Vector2(cactusSize, cactusSize),
      position: Vector2(size.x + 20, size.y - _groundHeight - cactusSize),
    );

    _cacti.add(cactus);
    add(cactus);
  }

  double _getRandomSafeY(double objHeight) {
    final double groundTop = size.y - _groundHeight;
    final bool spawnAbovePlatform = _rng.nextBool();

    if (spawnAbovePlatform) {
      final double offset = (130 + _rng.nextDouble() * 30) * _scale;
      return groundTop - objHeight - offset;
    } else {
      final double offset = (10 + _rng.nextDouble() * 20) * _scale;
      return groundTop - objHeight - offset;
    }
  }

  void _spawnCoin() {
    final double yPos = _getRandomSafeY(_coinSize);
    final SpriteComponent coin = SpriteComponent(
      sprite: _coinSprite,
      size: Vector2.all(_coinSize),
      position: Vector2(size.x + 20, yPos),
    );

    _coins.add(coin);
    add(coin);
  }

  void _updateCoins(double dt) {
    for (final SpriteComponent coin in List.of(_coins)) {
      coin.position.x -= _scrollSpeed * dt;

      if (coin.position.x + coin.size.x < -20) {
        _coins.remove(coin);
        coin.removeFromParent();
      }
    }
  }

  void _checkCoinCollision() {
    final Rect dinoRect = Rect.fromLTWH(
      _dino.position.x,
      _dino.position.y,
      _dinoSize.x,
      _dinoSize.y,
    );

    for (final SpriteComponent coin in List.of(_coins)) {
      final Rect coinRect = Rect.fromLTWH(
        coin.position.x,
        coin.position.y,
        coin.size.x,
        coin.size.y,
      );

      if (dinoRect.overlaps(coinRect)) {
        _coins.remove(coin);
        coin.removeFromParent();
        _collectCoin(coin.position);
      }
    }
  }

  void _collectCoin(Vector2 position) {
    _coinPool.start(volume: 0.5);
    _coinCount++;
    _coinText.text = '$_coinCount';

    final effect = PlusOneEffect(position: position.clone(), scale: _scale);
    add(effect);
  }

  void _spawnBox() {
    final double boxSize = 30 * _scale;
    final double yPos = _getRandomSafeY(boxSize);
    final RectangleComponent box = RectangleComponent(
      size: Vector2.all(boxSize),
      position: Vector2(size.x + 20, yPos),
      paint: Paint()..color = Colors.red,
    );
    _boxes.add(box);
    add(box);
  }

  void _updateBoxes(double dt) {
    for (final RectangleComponent box in List.of(_boxes)) {
      box.position.x -= _scrollSpeed * dt;
      if (box.position.x + box.size.x < -20) {
        _boxes.remove(box);
        box.removeFromParent();
      }
    }
  }

  void _checkBoxCollision() {
    final Rect dinoRect = Rect.fromLTWH(
      _dino.position.x,
      _dino.position.y,
      _dinoSize.x,
      _dinoSize.y,
    );

    for (final RectangleComponent box in List.of(_boxes)) {
      final Rect boxRect = Rect.fromLTWH(
        box.position.x,
        box.position.y,
        box.size.x,
        box.size.y,
      );

      if (dinoRect.overlaps(boxRect)) {
        _boxes.remove(box);
        box.removeFromParent();
        _collectBox();
      }
    }
  }

  void _collectBox() {
    FlameAudio.play('secre.wav', volume: 0.6);
    _isRunning = false;
    if (movies.isNotEmpty) {
      currentMovie = movies[_rng.nextInt(movies.length)];
    }
    overlays.add('secretMessage');
  }

  void resumeGame() {
    overlays.remove('secretMessage');
    _isRunning = true;
  }

  void _spawnCloud() {
    // Kích thước ngẫu nhiên đa dạng hơn
    final double scaleRatio = 0.2 + _rng.nextDouble() * 0.6;
    final double cloudWidth = _cloudSprite.srcSize.x * scaleRatio * _scale;
    final double cloudHeight = _cloudSprite.srcSize.y * scaleRatio * _scale;

    // Vị trí Y trải dài từ đỉnh màn hình đến sát mặt đất
    final double yPos =
        _rng.nextDouble() * (size.y - _groundHeight - cloudHeight);

    final SpriteComponent cloud = SpriteComponent(
      sprite: _cloudSprite,
      size: Vector2(cloudWidth, cloudHeight),
      // Cho mây xuất hiện lệch nhau một chút để không bị trùng hàng
      position: Vector2(size.x + _rng.nextDouble() * 100, yPos),
      priority: -1,
    );

    // Lưu tỉ lệ scale để tính toán tốc độ trôi (Parallax)
    // Mây càng nhỏ trôi càng chậm
    cloud.add(CloudData(speedMultiplier: 0.3 + (scaleRatio * 0.4)));

    _clouds.add(cloud);
    add(cloud);
  }

  void _updateClouds(double dt) {
    for (final SpriteComponent cloud in List.of(_clouds)) {
      final data = cloud.children.query<CloudData>().firstOrNull;
      final multiplier = data?.speedMultiplier ?? 0.5;

      cloud.position.x -= (_scrollSpeed * multiplier) * dt;

      if (cloud.position.x + cloud.size.x < -100) {
        _clouds.remove(cloud);
        cloud.removeFromParent();
      }
    }
  }

  double _spawnPlatform({double? initialX}) {
    final double height = _platformSprite.srcSize.y * _platformHeightScale;
    final double tileWidth = _platformSprite.srcSize.x * _platformHeightScale;
    const List<int> tileCounts = [2, 3, 4, 5];
    final int tiles = tileCounts[_rng.nextInt(tileCounts.length)];
    final double width = tileWidth * tiles;
    final double groundTop = size.y - _groundHeight;
    final double minY = groundTop - _platformMinOffset;
    final double maxY = groundTop - _platformMaxOffset;
    final double y = minY + _rng.nextDouble() * (maxY - minY);

    final TiledStripComponent platform = TiledStripComponent(
      sprite: _platformSprite,
      tileCount: tiles,
      tileWidth: tileWidth,
      size: Vector2(width, height),
      position: Vector2(initialX ?? (size.x + 40), y),
    );

    _platforms.add(platform);
    add(platform);
    return width;
  }

  void _updateObstacles(double dt) {
    for (final SpriteComponent cactus in List.of(_cacti)) {
      cactus.position.x -= _scrollSpeed * dt;

      if (cactus.position.x + cactus.size.x < -20) {
        _cacti.remove(cactus);
        cactus.removeFromParent();
      }
    }
  }

  void _updatePlatforms(double dt) {
    for (final TiledStripComponent platform in List.of(_platforms)) {
      platform.position.x -= _scrollSpeed * dt;

      if (platform.position.x + platform.size.x < -40) {
        _platforms.remove(platform);
        platform.removeFromParent();
      }
    }
  }

  void _updatePlayer(double dt) {
    _velocity.y += _gravity * dt;

    Vector2 nextPosition = _dino.position + _velocity * dt;
    final Rect currentRect = Rect.fromLTWH(
      _dino.position.x,
      _dino.position.y,
      _dinoSize.x,
      _dinoSize.y,
    );
    final Rect nextRect = Rect.fromLTWH(
      nextPosition.x,
      nextPosition.y,
      _dinoSize.x,
      _dinoSize.y,
    );

    final Rect groundRect = Rect.fromLTWH(
      _ground.position.x,
      _ground.position.y,
      _ground.size.x,
      _ground.size.y,
    );

    double? landingTop;
    if (_isLandingOnSurface(currentRect, nextRect, groundRect)) {
      landingTop = groundRect.top;
    }

    for (final TiledStripComponent platform in _platforms) {
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
      nextPosition = Vector2(nextPosition.x, landingTop - _dinoSize.y);
      _velocity.y = 0;
    }

    _dino.position = Vector2(_dino.position.x, nextPosition.y);
  }

  void _checkCactusCollision() {
    if (_isInvulnerable) return;

    final Rect dinoRect = Rect.fromLTWH(
      _dino.position.x,
      _dino.position.y,
      _dinoSize.x,
      _dinoSize.y,
    );

    for (final SpriteComponent cactus in _cacti) {
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

  void _loseLife() {
    FlameAudio.play('bom.wav', volume: 0.6);
    if (_lives > 0) {
      _lives--;
      if (_hearts.isNotEmpty) {
        final heart = _hearts.removeLast();
        heart.removeFromParent();
      }
    }

    if (_lives <= 0) {
      gameOver();
    } else {
      _isInvulnerable = true;
      _invulnerableTimer = 2.0;
    }
  }

  void _spawnHitEffect(Vector2 position, Vector2 size) {
    _hitEffect?.removeFromParent();
    final double effectSize = math.max(size.x, size.y) * 2.8;
    _hitEffect = SpriteComponent(
      sprite: _hitSprite,
      size: Vector2.all(effectSize),
      position: Vector2(
        position.x + size.x / 2 - effectSize / 2,
        position.y + size.y / 2 - effectSize / 2,
      ),
    );
    _hitTimer = 0.4;
    add(_hitEffect!);
  }

  bool _isLandingOnSurface(Rect current, Rect next, Rect surface) {
    if (current.bottom > surface.top) {
      return false;
    }
    final bool isFalling = next.bottom >= surface.top;
    final bool overlapsX =
        next.right > surface.left && next.left < surface.right;
    return isFalling && overlapsX;
  }

  bool _isStandingOnSurface() {
    if (_velocity.y.abs() > 0.1) {
      return false;
    }

    final Rect dinoRect = Rect.fromLTWH(
      _dino.position.x,
      _dino.position.y,
      _dinoSize.x,
      _dinoSize.y,
    );
    final Rect groundRect = Rect.fromLTWH(
      _ground.position.x,
      _ground.position.y,
      _ground.size.x,
      _ground.size.y,
    );

    if ((dinoRect.bottom - groundRect.top).abs() < 0.5) {
      return true;
    }

    for (final TiledStripComponent platform in _platforms) {
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

  void gameOver() {
    _isRunning = false;
    _statusText.text = '';
    overlays.add('gameOver');
  }

  void restart() {
    overlays.remove('gameOver');
    for (final SpriteComponent cactus in List.of(_cacti)) {
      cactus.removeFromParent();
    }
    _cacti.clear();
    for (final TiledStripComponent platform in List.of(_platforms)) {
      platform.removeFromParent();
    }
    _platforms.clear();
    for (final SpriteComponent coin in List.of(_coins)) {
      coin.removeFromParent();
    }
    _coins.clear();
    for (final RectangleComponent box in List.of(_boxes)) {
      box.removeFromParent();
    }
    _boxes.clear();
    for (final SpriteComponent cloud in List.of(_clouds)) {
      cloud.removeFromParent();
    }
    _clouds.clear();
    _coinCount = 0;
    _coinText.text = '0';
    _lives = 3;
    _isInvulnerable = false;
    _dino.paint.color = Colors.white;
    for (final heart in _hearts) {
      heart.removeFromParent();
    }
    _hearts.clear();
    _createHearts();

    _velocity = Vector2.zero();
    _dino.position = Vector2(60 * _scale, size.y - _groundHeight - _dinoSize.y);
    _isRunning = true;
    _statusText.text = '';
    _obstacleTimer = 0.3;
    _platformTimer = 0.4;

    _spawnPlatform(initialX: size.x * 0.6);
  }

  void _applyScale() {
    if (size.y <= 0) {
      return;
    }

    _scale = size.y / GameConstants.baseHeight;
    _gravity = GameConstants.baseGravity * _scale;
    _jumpSpeed = GameConstants.baseJumpSpeed * _scale;
    _groundHeight = GameConstants.baseGroundHeight * _scale;
    _scrollSpeed = GameConstants.baseScrollSpeed * _scale;
    _platformHeightScale = GameConstants.basePlatformHeightScale * _scale;
    _platformMinOffset = GameConstants.basePlatformMinOffset * _scale;
    _platformMaxOffset = GameConstants.basePlatformMaxOffset * _scale;
    _cactusMinSize = GameConstants.baseCactusMin * _scale;
    _cactusRange = GameConstants.baseCactusRange * _scale;
    _dinoSize =
        Vector2(GameConstants.baseDinoWidth, GameConstants.baseDinoHeight) *
        _scale;
    _coinSize = GameConstants.baseCoinSize * _scale;
  }
}

class CloudData extends Component {
  final double speedMultiplier;
  CloudData({required this.speedMultiplier});
}

// Class mới để vẽ thanh HUD bo góc
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
    // Vẽ hình chữ nhật bo góc (RRect)
    final rrect = RRect.fromRectAndCorners(
      size.toRect(),
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
    canvas.drawRRect(rrect, paint);
  }
}
