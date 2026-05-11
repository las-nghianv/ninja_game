import 'dart:convert';
import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/media_preview.dart';

class MovieRepo {
  final String _apiKey = 'ca912b14f16546bedaa8fbac0babf439'; // Replace with your actual API Key
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<MediaPreview>> getTrendingMovies() async {
    final url = Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey&language=en-US&page=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        return results.map((json) => MediaPreview.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trending movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  /// Get YouTube Trailer Key for a specific movie
  Future<String?> getMovieTrailerKey(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/videos?api_key=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final trailer = results.firstWhere(
          (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer',
          orElse: () => null,
        );

        return trailer?['key'];
      }
      return null;
    } catch (e) {
      log('Error fetching trailer key for $movieId: $e');
      return null;
    }
  }

  // --- HIVE CACHE LOGIC ---

  bool isCacheValid() {
    final settingsBox = Hive.box('settings');
    final lastFetchTime = settingsBox.get('last_fetch_time') as int?;
    if (lastFetchTime == null) return false;

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastFetchTime);
    final now = DateTime.now();
    final difference = now.difference(lastDate).inDays;

    return difference < 3; // Cache valid for 3 days
  }

  List<MediaPreview> getCachedMovies() {
    final moviesBox = Hive.box<MediaPreview>('movies_cache');
    return moviesBox.values.toList();
  }

  Future<void> saveMoviesToCache(List<MediaPreview> movies) async {
    final moviesBox = Hive.box<MediaPreview>('movies_cache');
    await moviesBox.clear();
    await moviesBox.addAll(movies);

    final settingsBox = Hive.box('settings');
    await settingsBox.put('last_fetch_time', DateTime.now().millisecondsSinceEpoch);
  }
}