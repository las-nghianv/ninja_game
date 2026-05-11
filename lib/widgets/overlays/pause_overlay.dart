import 'package:flutter/material.dart';
import '../../game/dino_runner_game.dart';

/// Overlay dừng game, nhấn nút play để đếm ngược và tiếp tục.
class PauseOverlay extends StatelessWidget {
  final DinoRunnerGame game;
  const PauseOverlay({super.key, required this.game});

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
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
