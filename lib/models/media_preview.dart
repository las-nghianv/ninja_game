class MediaPreview {
  final int id;
  final String title;
  final String date;
  final String poster;
  final String overview;

  const MediaPreview({
    required this.id,
    required this.title,
    required this.date,
    required this.poster,
    required this.overview,
  });

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
