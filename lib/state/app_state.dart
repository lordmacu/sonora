import 'package:flutter/foundation.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../models/youtube_result.dart';
import '../services/download_manager.dart';
import '../services/library_service.dart';
import '../services/playlist_service.dart';

enum AppView { home, search, downloads, playlists, playlistDetail, import, settings }

/// Estado de navegación + cachés de librería/playlists. Coordina los servicios.
class AppState extends ChangeNotifier {
  AppState({
    required this.library,
    required this.playlistService,
    required this.downloads,
  }) {
    downloads.addListener(_onDownloadsChanged);
    refreshAll();
  }

  final LibraryService library;
  final PlaylistService playlistService;
  final DownloadManager downloads;

  AppView _view = AppView.home;
  String? _currentPlaylistId;
  bool _playerExpanded = false;

  List<Song> _downloadedSongs = [];
  Map<String, Song> _songsById = {};
  List<Playlist> _playlists = [];

  // Búsqueda persistida: sobrevive a la reconstrucción de SearchView (al
  // cambiar de vista o abrir el reproductor expandido).
  String _searchQuery = '';
  List<YoutubeResult> _searchResults = [];

  AppView get view => _view;
  String? get currentPlaylistId => _currentPlaylistId;
  bool get playerExpanded => _playerExpanded;
  List<Song> get downloadedSongs => _downloadedSongs;
  Map<String, Song> get songsById => _songsById;
  List<Playlist> get playlists => _playlists;
  String get searchQuery => _searchQuery;
  List<YoutubeResult> get searchResults => _searchResults;

  void setSearch(String query, List<YoutubeResult> results) {
    _searchQuery = query;
    _searchResults = results;
    // sin notifyListeners: SearchView gestiona su propio setState; esto es solo
    // un caché para restaurar al recrear la vista.
  }

  int _lastDoneCount = 0;

  void _onDownloadsChanged() {
    final done = downloads.tasks.values
        .where((t) => t.status == DownloadStatus.done)
        .length;
    if (done != _lastDoneCount) {
      _lastDoneCount = done;
      refreshLibrary();
    }
  }

  // --- navegación ---

  void go(AppView v) {
    _view = v;
    _playerExpanded = false;
    notifyListeners();
  }

  void openPlaylist(String id) {
    _currentPlaylistId = id;
    _view = AppView.playlistDetail;
    _playerExpanded = false;
    notifyListeners();
  }

  void setPlayerExpanded(bool v) {
    _playerExpanded = v;
    notifyListeners();
  }

  // --- datos ---

  Future<void> refreshAll() async {
    // Secuencial: la librería debe estar cargada antes de purgar huérfanos,
    // para no eliminar descargas que aún no tienen metadatos guardados.
    await refreshLibrary();
    await refreshPlaylists();
    await _purgeOrphanPlaylistSongs();
  }

  /// Elimina de las playlists los videoIds que ya no se pueden mostrar (ni
  /// descargados ni con metadatos): ids huérfanos de flujos antiguos.
  Future<void> _purgeOrphanPlaylistSongs() async {
    var changed = false;
    for (final pl in _playlists) {
      final ids = playlistService.songIdsOf(pl.id);
      final keep = ids
          .where((id) =>
              _songsById.containsKey(id) ||
              playlistService.songMeta(id) != null)
          .toList();
      if (keep.length != ids.length) {
        await playlistService.setSongs(pl.id, keep);
        changed = true;
      }
    }
    if (changed) await refreshPlaylists();
  }

  Future<void> refreshLibrary() async {
    _downloadedSongs = await library.getDownloadedSongs();
    _songsById = {for (final s in _downloadedSongs) s.id: s};
    notifyListeners();
  }

  Future<void> refreshPlaylists() async {
    _playlists = await playlistService.getAll();
    notifyListeners();
  }

  /// Resuelve los Song de una playlist respetando el orden guardado. Prefiere
  /// la versión descargada; si no, reconstruye un Song de streaming a partir de
  /// los metadatos guardados al agregarla.
  List<Song> songsOfPlaylist(String playlistId) {
    final ids = playlistService.songIdsOf(playlistId);
    return ids
        .map((id) {
          final downloaded = _songsById[id];
          if (downloaded != null) return downloaded;
          final meta = playlistService.songMeta(id);
          if (meta == null) return null;
          return Song(
            id: id,
            title: meta.title,
            author: meta.author,
            filePath: '',
            thumbnailUrl: meta.thumbnailUrl,
            durationSeconds: meta.durationSeconds,
            isYoutube: true,
          );
        })
        .whereType<Song>()
        .toList();
  }

  /// Agrega una canción a una playlist, guardando sus metadatos para que pueda
  /// mostrarse y reproducirse aunque no esté descargada.
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await playlistService.saveSongMeta(
      song.id,
      song.title,
      song.author,
      song.thumbnailUrl ?? '',
      song.durationSeconds,
    );
    await playlistService.addSong(playlistId, song.id);
    await refreshPlaylists();
  }

  Future<Playlist> createPlaylist(String name) async {
    final pl = await playlistService.create(name);
    await refreshPlaylists();
    return pl;
  }

  /// Primera canción de una playlist (para usar su carátula como cover).
  Song? firstSongOf(String playlistId) {
    final songs = songsOfPlaylist(playlistId);
    return songs.isEmpty ? null : songs.first;
  }

  /// Hasta [max] carátulas (local o remota) de las primeras canciones con
  /// imagen, para armar el cover en mosaico de la playlist.
  List<({String? localPath, String? url})> coverImagesOf(String playlistId,
      {int max = 4}) {
    final out = <({String? localPath, String? url})>[];
    for (final s in songsOfPlaylist(playlistId)) {
      final hasLocal = (s.thumbnailPath ?? '').isNotEmpty;
      final hasUrl = (s.thumbnailUrl ?? '').isNotEmpty;
      if (!hasLocal && !hasUrl) continue;
      out.add((localPath: s.thumbnailPath, url: s.thumbnailUrl));
      if (out.length >= max) break;
    }
    return out;
  }

  /// Una sola carátula para el sidebar: una imagen "aleatoria" pero estable por
  /// playlist (no parpadea entre reconstrucciones). null si no hay imágenes.
  ({String? localPath, String? url})? singleCoverOf(String playlistId) {
    final imgs = coverImagesOf(playlistId);
    if (imgs.isEmpty) return null;
    return imgs[playlistId.hashCode.abs() % imgs.length];
  }

  /// Conteo de canciones REALMENTE mostrables (descargadas o con metadatos),
  /// no los videoIds crudos: evita contar ids huérfanos que ya no se ven.
  int resolvedCountOf(String playlistId) => songsOfPlaylist(playlistId).length;

  Playlist? playlistById(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> toggleFavorite(String videoId) async {
    await playlistService.toggleFavorite(videoId);
    await refreshPlaylists();
  }

  bool isFavorite(String videoId) => playlistService.isFavorite(videoId);

  @override
  void dispose() {
    downloads.removeListener(_onDownloadsChanged);
    super.dispose();
  }
}
