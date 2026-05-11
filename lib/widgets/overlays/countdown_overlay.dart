import 'package:flutter/material.dart';
import '../../game/dino_runner_game.dart';

/// Overlay đếm ngược 3-2-1 trước khi game tiếp tục.
class CountdownOverlay extends StatefulWidget {
  final DinoRunnerGame game;
  const CountdownOverlay({super.key, required this.game});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
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
              Shadow(
                color: Colors.black45,
                offset: Offset(4, 4),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
