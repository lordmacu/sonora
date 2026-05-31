/// Una canción descargada o local, lista para reproducir.
class Song {
  /// Para canciones de YouTube es el videoId; para locales, la ruta del archivo.
  final String id;
  final String title;
  final String author;

  /// Ruta absoluta del archivo de audio (m4a/mp3/etc).
  final String filePath;

  /// Ruta local de la miniatura (si existe).
  final String? thumbnailPath;

  /// URL remota de la miniatura (para resultados de búsqueda no descargados).
  final String? thumbnailUrl;

  final int durationSeconds;
  final int fileSizeBytes;
  final int lastModifiedMs;

  /// true si proviene de YouTube (id == videoId), false si es archivo local.
  final bool isYoutube;

  const Song({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.thumbnailPath,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.fileSizeBytes = 0,
    this.lastModifiedMs = 0,
    this.isYoutube = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'filePath': filePath,
        'thumbnailPath': thumbnailPath,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'fileSizeBytes': fileSizeBytes,
        'lastModifiedMs': lastModifiedMs,
        'isYoutube': isYoutube,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? '',
        author: (json['author'] as String?) ?? '',
        filePath: (json['filePath'] as String?) ?? '',
        thumbnailPath: json['thumbnailPath'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        durationSeconds: (json['durationSeconds'] as int?) ?? 0,
        fileSizeBytes: (json['fileSizeBytes'] as int?) ?? 0,
        lastModifiedMs: (json['lastModifiedMs'] as int?) ?? 0,
        isYoutube: (json['isYoutube'] as bool?) ?? true,
      );

  Song copyWith({
    String? title,
    String? author,
    String? thumbnailPath,
    int? durationSeconds,
  }) {
    return Song(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes,
      lastModifiedMs: lastModifiedMs,
      isYoutube: isYoutube,
    );
  }
}
