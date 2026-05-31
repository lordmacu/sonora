enum TrackDownloadState { pending, searching, downloading, done, error }

/// Una pista leída de un CSV de Spotify, en proceso de descarga.
class ImportTrack {
  final String id;
  final String name;
  final String artists;
  final String albumName;
  final int durationMs;

  String? videoId;
  TrackDownloadState state;
  bool selected;
  double progress; // 0..1

  ImportTrack({
    required this.id,
    required this.name,
    required this.artists,
    this.albumName = '',
    this.durationMs = 0,
    this.videoId,
    this.state = TrackDownloadState.pending,
    this.selected = true,
    this.progress = 0,
  });

  String get searchQuery => '$name $artists';
}
