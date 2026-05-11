// ignore_for_file: deprecated_member_use

import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../game/dino_runner_game.dart';
import '../../models/media_preview.dart';

/// Overlay hiện thông tin phim bí mật khi người chơi chạm vào hộp quà.
class SecretMessageOverlay extends StatefulWidget {
  final DinoRunnerGame game;
  const SecretMessageOverlay({super.key, required this.game});

  @override
  State<SecretMessageOverlay> createState() => _SecretMessageOverlayState();
}

class _SecretMessageOverlayState extends State<SecretMessageOverlay> {
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
                _buildPosterImage(movie.poster),
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
                _buildActionButtons(movie),
              ],
            ),
          ),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildPosterImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
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
          child: const Icon(Icons.movie, size: 50, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActionButtons(MediaPreview movie) {
    return Row(
      children: [
        Expanded(child: _buildAddToListButton(movie)),
        const SizedBox(width: 12),
        Expanded(child: _buildPlayTrailerButton(movie)),
      ],
    );
  }

  Widget _buildAddToListButton(MediaPreview movie) {
    return GestureDetector(
      onTap: () {
        if (!_isAdded) {
          setState(() => _isAdded = true);
          log('User clicked: Add to My List - ${movie.title}');
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Add to My List',
                  key: ValueKey('add'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlayTrailerButton(MediaPreview movie) {
    return ElevatedButton(
      onPressed: () async {
        if (movie.trailerKey != null && movie.trailerKey!.isNotEmpty) {
          final Uri url = Uri.parse(
            'https://www.youtube.com/watch?v=${movie.trailerKey}',
          );
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            log('Could not launch $url');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không tìm thấy Trailer cho phim này'),
              ),
            );
          }
        }
        widget.game.showPauseMenu();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text(
        'Play Trailer',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
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
    );
  }
}
