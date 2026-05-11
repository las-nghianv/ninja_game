import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_preview.dart';

class MovieRepo {
  final String _apiKey = 'ca912b14f16546bedaa8fbac0babf439'; // Cần thay bằng API Key thực tế của bạn
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
}