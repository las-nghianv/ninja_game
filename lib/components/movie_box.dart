import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import '../models/media_preview.dart';

class MovieBox extends SpriteComponent with HasGameRef {
  final MediaPreview movie;

  MovieBox({
    required this.movie,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size) {
    // Màu nền tối cho hộp
    paint = Paint()..color = const Color(0xFF1A1A1A);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // 1. Vẽ bóng đổ/phát sáng nhẹ
    canvas.drawRRect(
      rrect.shift(const Offset(2, 2)),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 2. Vẽ nền hộp
    canvas.drawRRect(rrect, paint);

    // 3. Vẽ Poster (nếu có)
    if (sprite != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      super.render(canvas);
      canvas.restore();
    } else {
      // Nếu chưa có ảnh, vẽ icon Mystery hoặc dấu chấm hỏi
      _renderMysteryIcon(canvas, rect);
    }

    // 4. Vẽ khung viền (Border) màu vàng/neon cho nổi bật
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderMysteryIcon(Canvas canvas, Rect rect) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    if (movie.poster.isNotEmpty) {
      try {
        // Ưu tiên lấy từ cache (đã được pre-load)
        if (Flame.images.containsKey(movie.poster)) {
          sprite = Sprite(Flame.images.fromCache(movie.poster));
          return;
        }

        // Fallback nếu pre-load chưa xong hoặc lỗi
        final response = await http.get(Uri.parse(movie.poster));
        if (response.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frame = await codec.getNextFrame();
          final image = frame.image;
          Flame.images.add(movie.poster, image);
          sprite = Sprite(image);
        }
      } catch (e) {
        debugPrint('Error loading movie poster: $e');
      }
    }
  }
}
