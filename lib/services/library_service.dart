import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

/// Gestiona el catálogo de canciones descargadas (archivos + metadata) y el
/// escaneo de una carpeta local de música. Equivalente a MusicLibrary.kt.
class LibraryService {
  LibraryService(this._prefs);

  final SharedPreferences _prefs;
  Directory? _audioDir;

  static const _supportedExt = {'mp3', 'flac', 'aac', 'ogg', 'wav', 'm4a', 'webm'};
  static const _keyLocalFolder = 'local_folder_path';

  /// Carpeta donde se guardan los audios descargados de YouTube.
  Future<Directory> audioDir() async {
    if (_audioDir != null) return _audioDir!;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'youtube_audio'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _audioDir = dir;
    return dir;
  }

  String audioFilePathSync(String basePath, String videoId, [String ext = 'm4a']) =>
      p.join(basePath, '$videoId.$ext');

  // --- metadata en SharedPreferences ---

  Future<void> saveMeta(String videoId, String title, String author,
      {String description = '', int durationSeconds = 0}) async {
    await _prefs.setString('title_$videoId', title);
    await _prefs.setString('author_$videoId', author);
    await _prefs.setString('desc_$videoId', description);
    if (durationSeconds > 0) {
      await _prefs.setInt('dur_$videoId', durationSeconds);
    }
  }

  Future<void> removeMeta(String videoId) async {
    await _prefs.remove('title_$videoId');
    await _prefs.remove('author_$videoId');
    await _prefs.remove('desc_$videoId');
    await _prefs.remove('dur_$videoId');
  }

  String descriptionOf(String videoId) => _prefs.getString('desc_$videoId') ?? '';

  /// Ruta de la miniatura local de un audio descargado.
  Future<String> thumbnailPath(String videoId) async {
    final dir = await audioDir();
    return p.join(dir.path, '$videoId.jpg');
  }

  /// Ruta del audio cacheado si existe (cualquier extensión soportada).
  Future<String?> cachedPath(String videoId) async {
    final dir = await audioDir();
    for (final ext in ['m4a', 'webm', 'mp3']) {
      final f = File(p.join(dir.path, '$videoId.$ext'));
      if (f.existsSync() && f.lengthSync() > 0) return f.path;
    }
    return null;
  }

  Future<bool> isDownloaded(String videoId) async => (await cachedPath(videoId)) != null;

  /// Lista todas las canciones descargadas con su metadata.
  Future<List<Song>> getDownloadedSongs() async {
    final dir = await audioDir();
    if (!dir.existsSync()) return [];
    final songs = <Song>[];
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).replaceFirst('.', '').toLowerCase();
      if (!{'m4a', 'webm', 'mp3'}.contains(ext)) continue;
      if (entity.lengthSync() == 0) continue;
      final videoId = p.basenameWithoutExtension(entity.path);
      final thumb = File(p.join(dir.path, '$videoId.jpg'));
      final stat = entity.statSync();
      songs.add(Song(
        id: videoId,
        title: _prefs.getString('title_$videoId') ?? videoId,
        author: _prefs.getString('author_$videoId') ?? '',
        filePath: entity.path,
        thumbnailPath: thumb.existsSync() ? thumb.path : null,
        durationSeconds: _prefs.getInt('dur_$videoId') ?? 0,
        fileSizeBytes: entity.lengthSync(),
        lastModifiedMs: stat.modified.millisecondsSinceEpoch,
        isYoutube: true,
      ));
    }
    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return songs;
  }

  Future<Map<String, Song>> getDownloadedSongsMap() async {
    final list = await getDownloadedSongs();
    return {for (final s in list) s.id: s};
  }

  Future<void> deleteDownload(String videoId) async {
    final dir = await audioDir();
    for (final ext in ['m4a', 'webm', 'mp3', 'jpg']) {
      final f = File(p.join(dir.path, '$videoId.$ext'));
      if (f.existsSync()) f.deleteSync();
    }
    await removeMeta(videoId);
  }

  Future<int> downloadedCount() async => (await getDownloadedSongs()).length;

  Future<int> totalDownloadedBytes() async {
    final list = await getDownloadedSongs();
    return list.fold<int>(0, (sum, s) => sum + s.fileSizeBytes);
  }

  // --- carpeta local ---

  String? get localFolder => _prefs.getString(_keyLocalFolder);

  Future<void> setLocalFolder(String path) => _prefs.setString(_keyLocalFolder, path);

  /// Escanea recursivamente una carpeta en busca de archivos de audio.
  Future<List<Song>> scanLocalFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return [];
    final songs = <Song>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).replaceFirst('.', '').toLowerCase();
      if (!_supportedExt.contains(ext)) continue;
      final stat = entity.statSync();
      songs.add(Song(
        id: entity.path,
        title: p.basenameWithoutExtension(entity.path),
        author: '',
        filePath: entity.path,
        fileSizeBytes: stat.size,
        lastModifiedMs: stat.modified.millisecondsSinceEpoch,
        isYoutube: false,
      ));
    }
    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return songs;
  }
}
