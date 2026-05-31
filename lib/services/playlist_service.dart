import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/playlist.dart';

/// Gestiona playlists (General, Favoritos protegidas + propias) y los
/// favoritos "online" (canciones marcadas que aún no se descargan).
/// Equivalente a PlaylistManager.kt + OnlineFavoritesStore.kt.
class PlaylistService {
  PlaylistService(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  static const _keyIds = 'pl_ids';
  static const generalId = Playlist.generalId;
  static const favoritesId = Playlist.favoritesId;
  static const _protected = {generalId, favoritesId};

  List<String> _ids() {
    final raw = _prefs.getString(_keyIds) ?? '';
    return raw.isEmpty ? [] : raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  Future<void> _setIds(List<String> ids) => _prefs.setString(_keyIds, ids.join(','));

  List<String> _songs(String id) {
    final raw = _prefs.getString('pl_s_$id') ?? '';
    return raw.isEmpty ? [] : raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  Future<void> _setSongs(String id, List<String> songs) =>
      _prefs.setString('pl_s_$id', songs.join(','));

  String displayName(String id) {
    if (id == generalId) return 'General';
    if (id == favoritesId) return 'Favoritos';
    return _prefs.getString('pl_n_$id') ?? id;
  }

  Future<List<Playlist>> getAll() async {
    final ids = _ids();
    var dirty = false;
    if (!ids.contains(generalId)) {
      ids.insert(0, generalId);
      await _prefs.setString('pl_n_$generalId', 'General');
      dirty = true;
    }
    if (!ids.contains(favoritesId)) {
      ids.insert(1.clamp(0, ids.length), favoritesId);
      await _prefs.setString('pl_n_$favoritesId', 'Favoritos');
      dirty = true;
    }
    if (dirty) await _setIds(ids);
    final ordered = [
      generalId,
      favoritesId,
      ...ids.where((id) => !_protected.contains(id)),
    ];
    return ordered
        .map((id) => Playlist(id: id, name: displayName(id), songIds: _songs(id)))
        .toList();
  }

  List<String> songIdsOf(String id) => _songs(id);

  int songCount(String id) => _songs(id).length;

  Future<Playlist> create(String name) async {
    final id = _uuid.v4();
    final ids = _ids()..add(id);
    await _setIds(ids);
    await _prefs.setString('pl_n_$id', name);
    await _setSongs(id, []);
    return Playlist(id: id, name: name, songIds: const []);
  }

  Future<void> rename(String id, String name) async {
    if (_protected.contains(id)) return;
    await _prefs.setString('pl_n_$id', name);
  }

  Future<void> delete(String id) async {
    if (_protected.contains(id)) return;
    final ids = _ids()..remove(id);
    await _setIds(ids);
    await _prefs.remove('pl_n_$id');
    await _prefs.remove('pl_s_$id');
  }

  Future<void> addSong(String playlistId, String videoId) async {
    final songs = _songs(playlistId);
    if (!songs.contains(videoId)) {
      songs.add(videoId);
      await _setSongs(playlistId, songs);
    }
  }

  Future<void> removeSong(String playlistId, String videoId) async {
    final songs = _songs(playlistId)..remove(videoId);
    await _setSongs(playlistId, songs);
  }

  /// Reemplaza la lista de canciones de una playlist (usado para purgar ids
  /// huérfanos). No toca las protegidas si se quisiera, pero aquí solo guarda.
  Future<void> setSongs(String playlistId, List<String> songs) =>
      _setSongs(playlistId, songs);

  // --- metadatos de canciones en playlists ---
  // Las playlists guardan solo videoIds; para que las canciones de streaming
  // (aún no descargadas) se puedan mostrar y reproducir desde una playlist,
  // persistimos sus metadatos por videoId.

  Future<void> saveSongMeta(
    String videoId,
    String title,
    String author,
    String thumbnailUrl,
    int durationSeconds,
  ) async {
    await _prefs.setString('psm_t_$videoId', title);
    await _prefs.setString('psm_a_$videoId', author);
    await _prefs.setString('psm_th_$videoId', thumbnailUrl);
    await _prefs.setInt('psm_d_$videoId', durationSeconds);
  }

  ({String title, String author, String thumbnailUrl, int durationSeconds})?
      songMeta(String videoId) {
    final title = _prefs.getString('psm_t_$videoId');
    if (title == null) return null;
    return (
      title: title,
      author: _prefs.getString('psm_a_$videoId') ?? '',
      thumbnailUrl: _prefs.getString('psm_th_$videoId') ?? '',
      durationSeconds: _prefs.getInt('psm_d_$videoId') ?? 0,
    );
  }

  // --- favoritos (playlist protegida) ---

  bool isFavorite(String videoId) => _songs(favoritesId).contains(videoId);

  Future<bool> toggleFavorite(String videoId) async {
    if (isFavorite(videoId)) {
      await removeSong(favoritesId, videoId);
      return false;
    }
    await addSong(favoritesId, videoId);
    return true;
  }

  // --- favoritos online (canciones streaming aún no descargadas) ---

  List<String> _onlineIds() {
    final raw = _prefs.getString('online_fav_ids') ?? '';
    return raw.isEmpty ? [] : raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  bool isOnlineFavorite(String videoId) => _onlineIds().contains(videoId);

  Future<bool> toggleOnlineFavorite(
      String videoId, String title, String author, String? thumbnailUrl) async {
    final ids = _onlineIds();
    if (ids.contains(videoId)) {
      ids.remove(videoId);
      await _prefs.setString('online_fav_ids', ids.join(','));
      await _prefs.remove('ofav_t_$videoId');
      await _prefs.remove('ofav_a_$videoId');
      await _prefs.remove('ofav_th_$videoId');
      return false;
    }
    ids.add(videoId);
    await _prefs.setString('online_fav_ids', ids.join(','));
    await _prefs.setString('ofav_t_$videoId', title);
    await _prefs.setString('ofav_a_$videoId', author);
    await _prefs.setString('ofav_th_$videoId', thumbnailUrl ?? '');
    return true;
  }
}
