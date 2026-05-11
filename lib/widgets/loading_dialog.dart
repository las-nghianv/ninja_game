import 'package:flutter/material.dart';
import '../data/movieRepo.dart';
import '../models/media_preview.dart';

/// Dialog hiển thị tiến trình tải dữ liệu phim và trailer trước khi vào game.
class LoadingDialog extends StatefulWidget {
  final Function(List<MediaPreview>) onComplete;
  const LoadingDialog({super.key, required this.onComplete});

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  double _progress = 0;
  String _status = 'Fetching movies...';
  final MovieRepo _movieRepo = MovieRepo();

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    try {
      // 1. Tải danh sách phim
      final movies = await _movieRepo.getTrendingMovies();
      setState(() {
        _progress = 0.3;
        _status = 'Movies fetched. Getting trailers...';
      });

      // 2. Tải Trailer Key cho từng phim
      List<MediaPreview> fullData = [];
      for (int i = 0; i < movies.length; i++) {
        final key = await _movieRepo.getMovieTrailerKey(movies[i].id);
        fullData.add(movies[i].copyWith(trailerKey: key));

        setState(() {
          _progress = 0.3 + (0.6 * (i + 1) / movies.length);
          _status = 'Loading trailers (${i + 1}/${movies.length})...';
        });
      }

      // 3. Lưu Cache
      setState(() => _status = 'Saving cache...');
      await _movieRepo.saveMoviesToCache(fullData);

      setState(() {
        _progress = 1.0;
        _status = 'Complete!';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete(fullData);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data loading error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PREPARING RESOURCES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF7941D),
              ),
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
