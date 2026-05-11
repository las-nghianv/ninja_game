// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../data/movieRepo.dart';
import '../models/media_preview.dart';
import '../widgets/loading_dialog.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MovieRepo _movieRepo = MovieRepo();
  List<MediaPreview> _movies = [];
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  void _checkCache() {
    if (_movieRepo.isCacheValid()) {
      _movies = _movieRepo.getCachedMovies();
      if (_movies.isNotEmpty) _isDataLoaded = true;
    }
  }

  Future<void> _initGameData() async {
    if (_isDataLoaded) {
      _navigateToGame();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(
        onComplete: (data) {
          setState(() {
            _movies = data;
            _isDataLoaded = true;
          });
          Navigator.pop(context);
          _navigateToGame();
        },
      ),
    );
  }

  void _navigateToGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(initialMovies: _movies),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC),
      body: Stack(
        children: [
          // ── Background clouds ────────────────────────────────────────────
          _cloud(top: 80, left: 40, width: 120),
          _cloud(top: 150, right: -20, width: 150),
          _cloud(bottom: 250, left: -30, width: 200),
          _cloud(bottom: 150, right: 20, width: 100),

          // ── Hero area ────────────────────────────────────────────────────
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Transform.scale(
                        scale: 1.4,
                        child: Image.asset(
                          'assets/images/cloud.png',
                          width: 400,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      left: 50,
                      child: Image.asset(
                        'assets/images/nhan_vat.png',
                        width: 80,
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      child: Image.asset(
                        'assets/images/banner.png',
                        width: 300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ── Ground ──────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/Frame 60.png',
              fit: BoxFit.cover,
              height: 100,
            ),
          ),

          // ── Start Button ─────────────────────────────────────────────────
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(child: _StartButton(onTap: _initGameData)),
          ),
        ],
      ),
    );
  }

  Widget _cloud({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double width,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Image.asset('assets/images/cloud.png', width: width),
    );
  }
}

/// Nút Start tách ra để tái sử dụng và giảm nesting.
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFF7941D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB45F06), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Start',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
