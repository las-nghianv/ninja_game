// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

import '../components/ground_component.dart';
import '../components/hud_bar.dart';
import '../components/strip_component.dart';
import '../const/game_constants.dart';
import '../models/media_preview.dart';
import 'collision_manager.dart';
import 'player_controller.dart';
import 'scroll_manager.dart';
import 'spawn_manager.dart';

/// Main Game: responsible for initialization, coordinating managers, and managing game lifecycle.
class DinoRunnerGame extends FlameGame {
  // ─── Sprites ─────────────────────────────────────────────────────────────
  late final TiledGroundComponent _ground;
  late final SpriteComponent _dino;
  late Sprite _cactusSprite;
  late Sprite _hitSprite;
  late Sprite _platformSprite;
  late Sprite _coinSprite;
  late Sprite _cloudSprite;

  // ─── HUD ─────────────────────────────────────────────────────────────────
  late final TextComponent _statusText;
  late final TextComponent _coinText;
  late final SpriteComponent _coinIcon;
  final List<TextComponent> _hearts = [];

  // ─── Audio ───────────────────────────────────────────────────────────────
  late AudioPool _jumpPool;
  late AudioPool _coinPool;

  // ─── Game object lists ───────────────────────────────────────────────────
  final List<SpriteComponent> _cacti = [];
  final List<SpriteComponent> _coins = [];
  final List<SpriteComponent> _clouds = [];
  final List<PositionComponent> _boxes = [];
  final List<TiledStripComponent> _platforms = [];

  // ─── Scale / Physics ─────────────────────────────────────────────────────
  double _scale = 1.0;
  Vector2 _dinoSize = Vector2(
    GameConstants.baseDinoWidth,
    GameConstants.baseDinoHeight,
  );
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

  // ─── State ───────────────────────────────────────────────────────────────
  Vector2 _velocity = Vector2.zero();
  int _coinCount = 0;
  int get coinCount => _coinCount;
  int _lives = 3;
  bool _isRunning = true;
  bool _isInvulnerable = false;
  double _invulnerableTimer = 0;
  double _hitTimer = 0;
  SpriteComponent? _hitEffect;

  // ─── Timers (spawn) ──────────────────────────────────────────────────────
  double _obstacleTimer = 0;
  double _platformTimer = 0;
  double _coinTimer = 0;
  double _boxTimer = 0;
  double _cloudTimer = 0;

  // ─── Movie data ──────────────────────────────────────────────────────────
  List<MediaPreview> movies = [];
  MediaPreview? currentMovie;

  // ─── Managers ────────────────────────────────────────────────────────────
  late final SpawnManager _spawnManager;
  late final ScrollManager _scrollManager;
  late final CollisionManager _collisionManager;
  late final PlayerController _playerController;

  final math.Random _rng = math.Random();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Color backgroundColor() => const Color(0xFFB3E5FC);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await FlameAudio.audioCache.loadAll(['bom.wav', 'secre.wav']);
    _jumpPool = await FlameAudio.createPool('jump.wav', maxPlayers: 3);
    _coinPool = await FlameAudio.createPool('coin.wav', maxPlayers: 4);

    _applyScale();

    // Load sprites
    final groundImage = await images.load('Frame 60.png');
    _ground = TiledGroundComponent(
      sprite: Sprite(groundImage),
      size: Vector2(size.x, _groundHeight),
      position: Vector2(0, size.y - _groundHeight),
    );
    final dinoImage = await images.load('nhan_vat.png');
    _dino = SpriteComponent(
      sprite: Sprite(dinoImage),
      size: _dinoSize,
      position: Vector2(60 * _scale, size.y - _groundHeight - _dinoSize.y),
    );
    _cactusSprite = Sprite(await images.load('Group 25.png'));
    _hitSprite = Sprite(await images.load('Group 27.png'));
    _platformSprite = Sprite(await images.load('Frame 59.png'));
    _coinSprite = Sprite(await images.load('coin.png'));
    _cloudSprite = Sprite(await images.load('cloud.png'));

    // HUD
    final double hudHeight = size.y * 0.1;
    add(HUDBar(
      size: Vector2(size.x, hudHeight),
      radius: 2 * _scale,
      color: const Color(0xFF88DBEF),
      priority: 10,
    ));

    _coinIcon = SpriteComponent(
      sprite: _coinSprite,
      size: Vector2.all(_coinSize),
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

    // Init managers
    _spawnManager = SpawnManager(_SpawnContext(this));
    _scrollManager = ScrollManager(_ScrollContext(this));
    _collisionManager = CollisionManager(_CollisionContext(this));
    _playerController = PlayerController(_PlayerContext(this));

    // Pre-load movie posters
    await _preloadMovieImages();

    // Spawn initial platforms
    final double w1 = _spawnManager.spawnPlatform(initialX: size.x * 0.55);
    _spawnManager.spawnPlatform(
      initialX: math.max(size.x * 0.9, size.x * 0.55 + w1 + 40 * _scale),
    );
  }

  // ─── HUD helpers ─────────────────────────────────────────────────────────
  void _createHearts() {
    final double hudHeight = size.y * 0.1;
    for (int i = 0; i < _lives; i++) {
      final heart = TextComponent(
        text: '❤️',
        textRenderer: TextPaint(style: TextStyle(fontSize: 24 * _scale)),
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

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyScale();
    if (!isLoaded) return;

    _ground.size = Vector2(size.x, _groundHeight);
    _ground.position = Vector2(0, size.y - _groundHeight);
    _dino.size = _dinoSize;
    final double groundTop = size.y - _groundHeight;
    if (_dino.position.y > groundTop - _dinoSize.y) {
      _dino.position.y = groundTop - _dinoSize.y;
    }

    final double hudHeight = size.y * 0.1;
    _coinIcon.size = Vector2.all(_coinSize);
    _coinIcon.position = Vector2(12 * _scale, hudHeight - _coinSize - 4 * _scale);
    _coinText.position =
        Vector2(40 * _scale, hudHeight - (18 * _scale) - 6 * _scale);

    for (int i = 0; i < _hearts.length; i++) {
      _hearts[i].position = Vector2(
        size.x - (36 * _scale * (i + 1)),
        hudHeight - (24 * _scale) - 4 * _scale,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Cập nhật hit effect timer
    if (_hitTimer > 0) {
      _hitTimer -= dt;
      if (_hitTimer <= 0) {
        _hitEffect?.removeFromParent();
        _hitEffect = null;
      }
    }

    // Nhấp nháy khi bất tử
    if (_isInvulnerable) {
      _invulnerableTimer -= dt;
      final bool isVisible = (_invulnerableTimer * 10).toInt() % 2 == 0;
      _dino.paint.color = Colors.white.withOpacity(isVisible ? 1.0 : 0.5);
      if (_invulnerableTimer <= 0) {
        _isInvulnerable = false;
        _dino.paint.color = Colors.white.withOpacity(1.0);
      }
    }

    if (!_isRunning) return;

    // Spawn timers
    _obstacleTimer -= dt;
    if (_obstacleTimer <= 0) {
      _spawnManager.spawnCactus();
      _obstacleTimer = 1.1 + _rng.nextDouble();
    }

    _platformTimer -= dt;
    if (_platformTimer <= 0) {
      final double width = _spawnManager.spawnPlatform();
      final double minTime = (width + 60 * _scale) / _scrollSpeed;
      _platformTimer = minTime + _rng.nextDouble() * 1.5;
    }

    _coinTimer -= dt;
    if (_coinTimer <= 0) {
      _spawnManager.spawnCoin();
      _coinTimer = 0.15 + _rng.nextDouble() * 0.3;
    }

    _boxTimer -= dt;
    if (_boxTimer <= 0) {
      _spawnManager.spawnBox();
      _boxTimer = 4.0 + _rng.nextDouble() * 4.0;
    }

    _cloudTimer -= dt;
    if (_cloudTimer <= 0) {
      _spawnManager.spawnCloud();
      _cloudTimer = 1.0 + _rng.nextDouble() * 2.0;
    }

    // Update via managers
    _scrollManager.updatePlatforms(dt);
    _scrollManager.updateObstacles(dt);
    _scrollManager.updateCoins(dt);
    _scrollManager.updateBoxes(dt);
    _scrollManager.updateClouds(dt);
    _playerController.update(dt);
    _collisionManager.checkCactusCollision();
    _collisionManager.checkCoinCollision();
    _collisionManager.checkBoxCollision();
  }

  // ─── Public game actions ─────────────────────────────────────────────────
  void jump() {
    if (!_isRunning) return;
    _playerController.jump();
  }

  void showPauseMenu() {
    overlays.remove('secretMessage');
    overlays.add('pauseMenu');
    _isRunning = false;
  }

  void startCountdown() {
    overlays.remove('pauseMenu');
    overlays.add('countdown');
  }

  void resumeGame() {
    overlays.remove('secretMessage');
    overlays.remove('countdown');
    _isRunning = true;
  }

  void gameOver() {
    _isRunning = false;
    _statusText.text = '';
    overlays.add('gameOver');
  }

  void restart() {
    overlays.remove('gameOver');
    _clearAllObjects();
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
    _spawnManager.spawnPlatform(initialX: size.x * 0.6);
  }

  // ─── Internal callbacks (được gọi bởi managers) ─────────────────────────
  void _incrementCoin() {
    _coinCount++;
    _coinText.text = '$_coinCount';
  }

  void _decrementLife() {
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

  void _onBoxCollected(MediaPreview? movie) {
    _isRunning = false;
    if (movie != null) {
      currentMovie = movie;
    } else if (movies.isNotEmpty) {
      currentMovie = movies[_rng.nextInt(movies.length)];
    }
    overlays.add('secretMessage');
  }

  void _clearAllObjects() {
    for (final c in List.of(_cacti)) {
      c.removeFromParent();
    }
    _cacti.clear();
    for (final c in List.of(_platforms)) {
      c.removeFromParent();
    }
    _platforms.clear();
    for (final c in List.of(_coins)) {
      c.removeFromParent();
    }
    _coins.clear();
    for (final c in List.of(_boxes)) {
      c.removeFromParent();
    }
    _boxes.clear();
    for (final c in List.of(_clouds)) {
      c.removeFromParent();
    }
    _clouds.clear();
  }

  // ─── Scale ───────────────────────────────────────────────────────────────
  void _applyScale() {
    if (size.y <= 0) return;
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
    _dinoSize = Vector2(
          GameConstants.baseDinoWidth,
          GameConstants.baseDinoHeight,
        ) *
        _scale;
    _coinSize = GameConstants.baseCoinSize * _scale;
  }

  Future<void> _preloadMovieImages() async {
    if (movies.isEmpty) return;
    
    // Only pre-load up to 10 movies to avoid overload
    final toPreload = movies.take(10).toList();
    
    final futures = toPreload.map((movie) async {
      if (movie.poster.isEmpty) return;
      if (images.containsKey(movie.poster)) return;
      
      try {
        final response = await http.get(Uri.parse(movie.poster));
        if (response.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frame = await codec.getNextFrame();
          images.add(movie.poster, frame.image);
        }
      } catch (e) {
        debugPrint('Error preloading ${movie.title}: $e');
      }
    });
    
    await Future.wait(futures);
  }
}

// ─── Context implementations ─────────────────────────────────────────────────

class _SpawnContext implements SpawnManagerContext {
  final DinoRunnerGame g;
  _SpawnContext(this.g);

  @override Vector2 get screenSize => g.size;
  @override double get scale => g._scale;
  @override double get groundHeight => g._groundHeight;
  @override double get coinSize => g._coinSize;
  @override double get cactusMinSize => g._cactusMinSize;
  @override double get cactusRange => g._cactusRange;
  @override double get platformHeightScale => g._platformHeightScale;
  @override double get platformMinOffset => g._platformMinOffset;
  @override double get platformMaxOffset => g._platformMaxOffset;
  @override Sprite get cactusSprite => g._cactusSprite;
  @override Sprite get coinSprite => g._coinSprite;
  @override Sprite get cloudSprite => g._cloudSprite;
  @override Sprite get platformSprite => g._platformSprite;
  @override List<SpriteComponent> get cacti => g._cacti;
  @override List<SpriteComponent> get coins => g._coins;
  @override List<SpriteComponent> get clouds => g._clouds;
  @override List<MediaPreview> get movies => g.movies;
  @override List<PositionComponent> get boxes => g._boxes;
  @override List<TiledStripComponent> get platforms => g._platforms;
  @override void addComponent(Component c) => g.add(c);
}

class _ScrollContext implements ScrollManagerContext {
  final DinoRunnerGame g;
  _ScrollContext(this.g);

  @override double get scrollSpeed => g._scrollSpeed;
  @override List<SpriteComponent> get cacti => g._cacti;
  @override List<SpriteComponent> get coins => g._coins;
  @override List<SpriteComponent> get clouds => g._clouds;
  @override List<PositionComponent> get boxes => g._boxes;
  @override List<TiledStripComponent> get platforms => g._platforms;
}

class _CollisionContext implements CollisionManagerContext {
  final DinoRunnerGame g;
  _CollisionContext(this.g);

  @override bool get isInvulnerable => g._isInvulnerable;
  @override double get scale => g._scale;
  @override Vector2 get dinoPosition => g._dino.position;
  @override Vector2 get dinoSize => g._dinoSize;
  @override Sprite get hitSprite => g._hitSprite;
  @override AudioPool get coinPool => g._coinPool;
  @override List<SpriteComponent> get cacti => g._cacti;
  @override List<SpriteComponent> get coins => g._coins;
  @override List<PositionComponent> get boxes => g._boxes;
  @override void addComponent(Component c) => g.add(c);
  @override void incrementCoin() => g._incrementCoin();
  @override void decrementLife() => g._decrementLife();
  @override void onBoxCollected(MediaPreview? movie) => g._onBoxCollected(movie);
  @override void removeCurrentHitEffect() {
    g._hitEffect?.removeFromParent();
    g._hitEffect = null;
  }
  @override void setHitEffect(SpriteComponent effect) {
    g._hitEffect = effect;
    g._hitTimer = 0.4;
  }
}

class _PlayerContext implements PlayerControllerContext {
  final DinoRunnerGame g;
  _PlayerContext(this.g);

  @override double get gravity => g._gravity;
  @override double get jumpSpeed => g._jumpSpeed;
  @override double get velocityY => g._velocity.y;
  @override AudioPool get jumpPool => g._jumpPool;
  @override Vector2 get dinoPosition => g._dino.position;
  @override Vector2 get dinoSize => g._dinoSize;
  @override Rect get groundRect => Rect.fromLTWH(
        g._ground.position.x,
        g._ground.position.y,
        g._ground.size.x,
        g._ground.size.y,
      );
  @override List<TiledStripComponent> get platforms => g._platforms;
  @override void setVelocityY(double v) => g._velocity.y = v;
  @override void addVelocityY(double delta) => g._velocity.y += delta;
  @override void setDinoY(double y) => g._dino.position.y = y;
  @override void onJumped() => g._statusText.text = '';
}
