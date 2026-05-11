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
    // Thêm một màu nền placeholder (ví dụ: xám đậm)
    paint = Paint()..color = const Color(0xFF333333);
  }

  @override
  void render(Canvas canvas) {
    // Vẽ placeholder trước
    canvas.drawRect(size.toRect(), paint);
    super.render(canvas);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    if (movie.poster.isNotEmpty) {
      try {
        // Kiểm tra cache của Flame trước
        if (Flame.images.containsKey(movie.poster)) {
          sprite = Sprite(Flame.images.fromCache(movie.poster));
          return;
        }

        // Nếu chưa có, tải từ network
        final response = await http.get(Uri.parse(movie.poster));
        if (response.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frame = await codec.getNextFrame();
          final image = frame.image;
          
          // Lưu vào cache để các hộp khác cùng phim không phải tải lại
          Flame.images.add(movie.poster, image);
          sprite = Sprite(image);
        }
      } catch (e) {
        print('Error loading movie poster: $e');
      }
    }
  }
}
