/// Resultado de búsqueda en YouTube / YouTube Music.
class YoutubeResult {
  final String videoId;
  final String title;
  final String author;
  final int durationSeconds;
  final String thumbnailUrl;

  const YoutubeResult({
    required this.videoId,
    required this.title,
    required this.author,
    this.durationSeconds = 0,
    this.thumbnailUrl = '',
  });
}
