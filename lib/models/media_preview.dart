import 'package:hive/hive.dart';

part 'media_preview.g.dart';

@HiveType(typeId: 0)
class MediaPreview extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String date;
  @HiveField(3)
  final String poster;
  @HiveField(4)
  final String overview;
  @HiveField(5)
  final String? trailerKey;

  MediaPreview({
    required this.id,
    required this.title,
    required this.date,
    required this.poster,
    required this.overview,
    this.trailerKey,
  });

  MediaPreview copyWith({
    int? id,
    String? title,
    String? date,
    String? poster,
    String? overview,
    String? trailerKey,
  }) {
    return MediaPreview(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      poster: poster ?? this.poster,
      overview: overview ?? this.overview,
      trailerKey: trailerKey ?? this.trailerKey,
    );
  }

  factory MediaPreview.fromJson(Map<String, dynamic> json) {
    return MediaPreview(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      date: json['release_date'] ?? json['first_air_date'] ?? '',
      poster: json['poster_path'] != null 
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}' 
          : '',
      overview: json['overview'] ?? '',
    );
  }
}
