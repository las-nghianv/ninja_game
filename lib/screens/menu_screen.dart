import 'package:flutter/material.dart';
import '../data/movieRepo.dart';
import '../models/media_preview.dart';
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
      if (_movies.isNotEmpty) {
        _isDataLoaded = true;
      }
    }
  }

  Future<void> _initGameData() async {
    if (_isDataLoaded) {
      _navigateToGame();
      return;
    }

    // Hiển thị Dialog tiến độ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(
        onComplete: (data) {
          setState(() {
            _movies = data;
            _isDataLoaded = true;
          });
          Navigator.pop(context); // Đóng dialog
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
          // Clouds Background
          Positioned(top: 80, left: 40, child: Image.asset('assets/images/cloud.png', width: 120)),
          Positioned(top: 150, right: -20, child: Image.asset('assets/images/cloud.png', width: 150)),
          Positioned(bottom: 250, left: -30, child: Image.asset('assets/images/cloud.png', width: 200)),
          Positioned(bottom: 150, right: 20, child: Image.asset('assets/images/cloud.png', width: 100)),

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
                        child: Image.asset('assets/images/cloud.png', width: 400),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      left: 50,
                      child: Image.asset('assets/images/nhan_vat.png', width: 80),
                    ),
                    Positioned(
                      bottom: 30,
                      child: Image.asset('assets/images/banner.png', width: 300),
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
            child: Image.asset('assets/images/Frame 60.png', fit: BoxFit.cover, height: 100),
          ),

          // Start Button
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _initGameData,
                child: Container(
                  width: 280,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7941D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFB45F06), width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 6), blurRadius: 0),
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
                        Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 2),
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

class _LoadingDialog extends StatefulWidget {
  final Function(List<MediaPreview>) onComplete;
  const _LoadingDialog({required this.onComplete});

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog> {
  double _progress = 0;
  String _status = 'Đang tải danh sách phim...';
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
        _status = 'Đã tải xong danh sách. Đang lấy Trailer...';
      });

      // 2. Tải Trailer Key cho từng phim
      List<MediaPreview> fullData = [];
      for (int i = 0; i < movies.length; i++) {
        final key = await _movieRepo.getMovieTrailerKey(movies[i].id);
        fullData.add(movies[i].copyWith(trailerKey: key));
        
        setState(() {
          _progress = 0.3 + (0.6 * (i + 1) / movies.length);
          _status = 'Đang tải trailer (${i + 1}/${movies.length})...';
        });
      }

      // 3. Lưu Cache
      setState(() {
        _status = 'Đang lưu cache...';
      });
      await _movieRepo.saveMoviesToCache(fullData);
      
      setState(() {
        _progress = 1.0;
        _status = 'Hoàn tất!';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete(fullData);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
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
              'ĐANG CHUẨN BỊ TÀI NGUYÊN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF7941D)),
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

