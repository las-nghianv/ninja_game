// ignore_for_file: deprecated_member_use

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/dino_runner_game.dart';
import '../models/media_preview.dart';
import '../widgets/overlays/countdown_overlay.dart';
import '../widgets/overlays/game_over_overlay.dart';
import '../widgets/overlays/pause_overlay.dart';
import '../widgets/overlays/secret_message_overlay.dart';

class GameScreen extends StatefulWidget {
  final List<MediaPreview> initialMovies;
  const GameScreen({super.key, required this.initialMovies});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final DinoRunnerGame _game;

  @override
  void initState() {
    super.initState();
    _game = DinoRunnerGame();
    _game.movies = widget.initialMovies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Game Layer ───────────────────────────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _game.jump,
            child: GameWidget<DinoRunnerGame>(
              game: _game,
              loadingBuilder: (context) => const _GameLoadingScreen(),
              overlayBuilderMap: {
                'gameOver': (context, game) =>
                    GameOverOverlay(game: game),
                'secretMessage': (context, game) =>
                    SecretMessageOverlay(game: game),
                'pauseMenu': (context, game) =>
                    PauseOverlay(game: game),
                'countdown': (context, game) =>
                    CountdownOverlay(game: game),
              },
            ),
          ),

          // ── Home Button ──────────────────────────────────────────────────
          Positioned(
            bottom: 10,
            left: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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

/// Widget hiển thị trong khi Flame đang load assets.
class _GameLoadingScreen extends StatelessWidget {
  const _GameLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFB3E5FC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
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
    );
  }
}
