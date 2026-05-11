// ignore_for_file: deprecated_member_use

import 'dart:developer';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dino_game.dart';
import '../models/media_preview.dart';

class GameScreen extends StatefulWidget {
  final List<MediaPreview> initialMovies;
  const GameScreen({super.key, required this.initialMovies});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final DinoRunnerGame _game;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _game = DinoRunnerGame();
    _game.movies = widget.initialMovies;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFB3E5FC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'ĐANG TẢI PHIM TRENDING...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Game Layer
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _game.jump();
            },
            child: GameWidget<DinoRunnerGame>(
              game: _game,
              loadingBuilder: (context) => Scaffold(
                backgroundColor: const Color(0xFFB3E5FC),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'LOADING...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              overlayBuilderMap: {
                'gameOver': (context, game) => _GameOverOverlay(game: game),
                'secretMessage': (context, game) =>
                    _SecretMessageOverlay(game: game),
                'pauseMenu': (context, game) => _PauseOverlay(game: game),
                'countdown': (context, game) => _CountdownOverlay(game: game),
              },
            ),
          ),

          // Home Button at Bottom Left
          Positioned(
            bottom: 10,
            left: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),

                child: Image.asset(
                  'assets/images/home.png',
                  width: 60,
                  height: 60,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretMessageOverlay extends StatefulWidget {
  final DinoRunnerGame game;
  const _SecretMessageOverlay({required this.game});

  @override
  State<_SecretMessageOverlay> createState() => _SecretMessageOverlayState();
}

class _SecretMessageOverlayState extends State<_SecretMessageOverlay> {
  bool _isAdded = false;

  @override
  Widget build(BuildContext context) {
    final movie = widget.game.currentMovie;
    if (movie == null) return const SizedBox.shrink();

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 350, maxHeight: 600),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDB042),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: movie.poster,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.black12,
                      highlightColor: Colors.black26,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.black26,
                      child: const Icon(
                        Icons.movie,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Over View',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      movie.overview,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isAdded) {
                            setState(() => _isAdded = true);
                            log('User clicked: Add to My List - ${movie.title}');
                            // Giữ lại 1 giây để người dùng thấy hiệu ứng rồi mới tắt (tùy chọn)
                            Future.delayed(const Duration(milliseconds: 800), () {
                              if (mounted) widget.game.resumeGame();
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isAdded ? const Color(0xFF4CAF50) : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isAdded
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Added',
                                        key: ValueKey('added'),
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Add to My List',
                                    key: ValueKey('add'),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (movie.trailerKey != null &&
                              movie.trailerKey!.isNotEmpty) {
                            final Uri url = Uri.parse(
                                'https://www.youtube.com/watch?v=${movie.trailerKey}');
                            if (!await launchUrl(url,
                                mode: LaunchMode.externalApplication)) {
                              log('Could not launch $url');
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Không tìm thấy Trailer cho phim này')),
                            );
                          }
                          // Thay vì resume ngay, hãy hiện menu Pause
                          widget.game.showPauseMenu();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Play Trailer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            right: -10,
            child: GestureDetector(
              onTap: () => widget.game.resumeGame(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEC321),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final DinoRunnerGame game;

  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFDB042),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 40)),
                      Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          height: 45,
                          width: 3,
                          color: Colors.black,
                        ),
                      ),
                      Transform.rotate(
                        angle: 0.5,
                        child: Container(
                          height: 45,
                          width: 3,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.yellow[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '\$',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  game.coinCount.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => game.restart(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'TRY AGAIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final DinoRunnerGame game;
  const _PauseOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: GestureDetector(
          onTap: () => game.startCountdown(),
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFF7941D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _CountdownOverlay extends StatefulWidget {
  final DinoRunnerGame game;
  const _CountdownOverlay({required this.game});

  @override
  State<_CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<_CountdownOverlay> {
  int _seconds = 3;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _seconds = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    widget.game.resumeGame();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Text(
          '$_seconds',
          style: const TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black45, offset: Offset(4, 4), blurRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}
