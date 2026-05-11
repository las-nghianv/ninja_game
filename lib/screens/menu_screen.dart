import 'package:flutter/material.dart';
import 'game_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC),
      body: Stack(
        children: [
          // Clouds Background
          Positioned(
            top: 80,
            left: 40,
            child: Image.asset('assets/images/cloud.png', width: 120),
          ),
          Positioned(
            top: 150,
            right: -20,
            child: Image.asset('assets/images/cloud.png', width: 150),
          ),
          Positioned(
            bottom: 250,
            left: -30,
            child: Image.asset('assets/images/cloud.png', width: 200),
          ),
          Positioned(
            bottom: 150,
            right: 20,
            child: Image.asset('assets/images/cloud.png', width: 100),
          ),

          // Main Center Content
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ninja on Cloud + Banner
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
                    // Banner được đưa vào trong Stack
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

          // Ground at bottom
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

          // Start Button
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GameScreen()),
                  );
                },
                child: Container(
                  width: 280,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7941D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFB45F06),
                      width: 4,
                    ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
