import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import 'download_manager.dart';
import 'youtube_service.dart';

enum RepeatMode { none, all, one }

/// Reproductor: gestiona su propia cola para soportar archivos locales,
/// streaming de YouTube y "radio" (anexar pistas). Envuelve media_kit.
class PlayerService extends ChangeNotifier {
  PlayerService(this._youtube, {DownloadManager? downloads, SharedPreferences? prefs})
      : _downloads = downloads,
        _prefs = prefs {
    _player.stream.playing.listen((v) {
      _playing = v;
      // una reproducción exitosa limpia el guardado de recuperación
      if (v) _recoveryAttempted.clear();
      notifyListeners();
    });
    _player.stream.position.listen((v) {
      _position = v;
      if (v.inSeconds >= _listenedThresholdSeconds) _maybeCacheCurrent();
      // persistir posición de forma espaciada (cada ~5 s) para poder reanudar
      if (v.inSeconds != _lastSavedPosSec && v.inSeconds % 5 == 0) {
        _lastSavedPosSec = v.inSeconds;
        _saveState();
      }
      notifyListeners();
    });
    _player.stream.duration.listen((v) {
      if (v > Duration.zero) {
        _duration = v;
        notifyListeners();
      }
    });
    _player.stream.buffering.listen((v) {
      _buffering = v;
      notifyListeners();
    });
    _player.stream.completed.listen((completed) {
      if (completed) _onCompleted();
    });
    _player.stream.error.listen((e) {
      debugPrint('media_kit ERROR: $e');
      _recoverFromError();
    });
    _player.stream.log.listen((e) {
      debugPrint('media_kit log: ${e.level} ${e.prefix}: ${e.text}');
    });
    // Dispositivos de salida (incluye Bluetooth ya emparejado en el SO).
    _player.stream.audioDevices.listen((v) {
      _audioDevices = v;
      notifyListeners();
    });
    _player.stream.audioDevice.listen((v) {
      _audioDevice = v;
      notifyListeners();
    });
  }

  final YoutubeService _youtube;
  final DownloadManager? _downloads;
  final SharedPreferences? _prefs;
  final Player _player = Player();
  final _rng = Random();

  static const _kStateKey = 'player_state_v1';

  /// Cachear a disco automáticamente las canciones de streaming al reproducirlas.
  bool autoCacheStreaming = true;

  /// videoIds para los que ya intentamos recuperar tras un error (evita bucles).
  final Set<String> _recoveryAttempted = {};

  /// true cuando la cola es "tipo radio" (una canción suelta de streaming) y
  /// debe autoextenderse; false para playlists/listas explícitas.
  bool _radioEnabled = false;
  bool _extending = false;

  /// Generación de apertura: cada _openCurrent/_recoverFromError la incrementa;
  /// una apertura cuya generación quedó obsoleta se descarta (anti-carrera).
  int _openGen = 0;

  /// videoIds para los que ya pedimos descarga oportunista (una vez por canción).
  final Set<String> _cacheRequested = {};

  /// Cuántas pistas ya reproducidas conservar antes de la actual en modo radio.
  static const _radioHistoryWindow = 20;

  /// Segundos reproducidos para considerar que la canción se "escuchó" (cachear).
  static const _listenedThresholdSeconds = 20;

  Timer? _saveTimer;
  int _lastSavedPosSec = -1;

  // Salida de audio (Bluetooth/altavoces/etc.). 'auto' = salida del sistema.
  List<AudioDevice> _audioDevices = const [AudioDevice('auto', '')];
  AudioDevice _audioDevice = const AudioDevice('auto', '');

  final List<Song> _queue = [];
  List<int> _order = []; // índices en orden de reproducción (afectado por shuffle)
  int _orderPos = -1;

  bool _playing = false;
  bool _buffering = false;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.none;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _resolving = false;

  // getters
  /// Cola en el ORDEN REAL de reproducción (respeta shuffle), no el de inserción.
  List<Song> get queue =>
      List.unmodifiable(_order.map((i) => _queue[i]));
  bool get playing => _playing;
  bool get buffering => _buffering || _resolving;
  bool get shuffle => _shuffle;
  bool get radioEnabled => _radioEnabled;
  RepeatMode get repeat => _repeat;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasSong => _orderPos >= 0 && _orderPos < _order.length;

  /// Dispositivos de salida disponibles y el actualmente seleccionado.
  List<AudioDevice> get audioDevices => _audioDevices;
  AudioDevice get audioDevice => _audioDevice;
  Future<void> setAudioDevice(AudioDevice device) =>
      _player.setAudioDevice(device);

  Song? get current {
    if (!hasSong) return null;
    final idx = _order[_orderPos];
    if (idx < 0 || idx >= _queue.length) return null;
    return _queue[idx];
  }

  // ---------------------------------------------------------------------------
  // Reproducción
  // ---------------------------------------------------------------------------

  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    // La radio (autoplay de relacionados) se habilita si hay contenido de
    // YouTube, sea una canción suelta o una lista: al agotarse la cola continúa
    // con relacionados remotos. Los imports locales puros quedan como cola
    // finita. Siempre se puede desactivar con el toggle de Radio.
    _radioEnabled = songs.any((s) => s.isYoutube);
    _queue
      ..clear()
      ..addAll(songs);
    _buildOrder(firstIndex: startIndex);
    // _openCurrent siembra la radio si la cola está por agotarse (p. ej. una
    // sola canción), respetando _radioEnabled.
    await _openCurrent();
  }

  Future<void> playSingle(Song song) => playSongs([song]);

  /// Activa/desactiva el modo radio (autoplay de relacionados). Al activarlo
  /// siembra relacionados si la cola está por agotarse.
  Future<void> toggleRadio() async {
    _radioEnabled = !_radioEnabled;
    notifyListeners();
    if (_radioEnabled) await _maybeExtendRadio();
  }

  /// Si la cola es tipo radio y quedan pocas pistas, anexa más relacionados de
  /// la canción actual. Best-effort: no bloquea ni rompe si falla la red.
  Future<void> _maybeExtendRadio() async {
    if (!_radioEnabled || _extending) return;
    final song = current;
    if (song == null || !song.isYoutube) return;
    final remaining = _order.length - 1 - _orderPos;
    if (remaining > 3) return;
    _extending = true;
    final seedId = song.id;
    try {
      final radio = await _youtube.getRadioQueue(seedId, maxItems: 15);
      if (current?.id != seedId) return; // el usuario cambió de pista
      final existing = _queue.map((s) => s.id).toSet();
      final fresh = radio
          .where((r) => r.videoId != seedId && !existing.contains(r.videoId))
          .map((r) => Song(
                id: r.videoId,
                title: r.title,
                author: r.author,
                filePath: '',
                thumbnailUrl: r.thumbnailUrl,
                durationSeconds: r.durationSeconds,
              ))
          .toList();
      if (fresh.isNotEmpty) addAllToQueue(fresh);
    } catch (_) {/* radio es best-effort */} finally {
      _extending = false;
    }
  }

  void addToQueue(Song song) {
    _queue.add(song);
    _order.add(_queue.length - 1);
    notifyListeners();
    _saveState();
  }

  void addAllToQueue(List<Song> songs) {
    for (final s in songs) {
      _queue.add(s);
      _order.add(_queue.length - 1);
    }
    notifyListeners();
    _saveState();
  }

  /// Quita de la cola todas las apariciones de [songId]. Si era la canción
  /// actual, detiene y oculta el reproductor (current queda null).
  void removeFromQueueById(String songId) {
    if (!_queue.any((s) => s.id == songId)) return;

    if (current?.id == songId) {
      _player.stop();
      _queue.clear();
      _order = [];
      _orderPos = -1;
      _playing = false;
      _buffering = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _radioEnabled = false;
      notifyListeners();
      _saveState();
      return;
    }

    // No es la actual: la quitamos preservando la canción en curso.
    final currentSong = current;
    final ordered =
        _order.map((i) => _queue[i]).where((s) => s.id != songId).toList();
    _queue
      ..clear()
      ..addAll(ordered);
    _order = List<int>.generate(_queue.length, (i) => i);
    _orderPos = currentSong == null
        ? -1
        : _queue.indexWhere((s) => s.id == currentSong.id);
    if (_orderPos < 0 && _queue.isNotEmpty) _orderPos = 0;
    notifyListeners();
    _saveState();
  }

  /// Inserta la canción justo después de la actual en el orden de reproducción.
  void playNext(Song song) {
    _queue.add(song);
    final qIdx = _queue.length - 1;
    final insertAt = (_orderPos < 0 ? 0 : _orderPos + 1).clamp(0, _order.length);
    _order.insert(insertAt, qIdx);
    notifyListeners();
    _saveState();
  }

  Future<void> togglePlay() async {
    if (!hasSong) return;
    await _player.playOrPause();
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> next({bool auto = false}) async {
    if (_order.isEmpty) return;
    if (_repeat == RepeatMode.one && auto) {
      await _openCurrent();
      return;
    }
    if (_orderPos + 1 < _order.length) {
      _orderPos++;
    } else {
      if (_repeat == RepeatMode.all || !auto) {
        _orderPos = 0;
      } else {
        await _player.pause();
        return;
      }
    }
    await _openCurrent();
  }

  Future<void> previous() async {
    if (_order.isEmpty) return;
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_orderPos - 1 >= 0) {
      _orderPos--;
    } else {
      _orderPos = _order.length - 1;
    }
    await _openCurrent();
  }

  /// [orderPos] es el índice dentro de [queue] (orden de reproducción).
  Future<void> jumpTo(int orderPos) async {
    if (orderPos < 0 || orderPos >= _order.length) return;
    _orderPos = orderPos;
    await _openCurrent();
  }

  Future<void> seek(Duration to) => _player.seek(to);

  void toggleShuffle() {
    _shuffle = !_shuffle;
    final currentQueueIdx = hasSong ? _order[_orderPos] : null;
    _buildOrder(firstQueueIndex: currentQueueIdx);
    notifyListeners();
    _saveState();
  }

  void cycleRepeat() {
    _repeat = switch (_repeat) {
      RepeatMode.none => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.none,
    };
    notifyListeners();
    _saveState();
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  void _buildOrder({int? firstIndex, int? firstQueueIndex}) {
    final indices = List<int>.generate(_queue.length, (i) => i);
    if (_shuffle) {
      indices.shuffle(_rng);
    }
    _order = indices;
    final target = firstQueueIndex ?? firstIndex ?? 0;
    final pos = _order.indexOf(target);
    _orderPos = pos >= 0 ? pos : 0;
    if (_shuffle && firstQueueIndex == null && firstIndex != null) {
      // mover la pista inicial al frente para que suene primero
      _order.remove(firstIndex);
      _order.insert(0, firstIndex);
      _orderPos = 0;
    }
  }

  Future<void> _openCurrent({bool autoplay = true, Duration? startAt}) async {
    _trimHistory();
    final song = current;
    if (song == null) return;
    final gen = ++_openGen;
    _resolving = true;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    try {
      final media = await _resolveMedia(song);
      if (gen != _openGen) return; // otra apertura más nueva ganó la carrera
      debugPrint('Abriendo ${song.title} -> ${media.uri.length > 80 ? '${media.uri.substring(0, 80)}...' : media.uri}');
      await _player.open(media, play: autoplay);
      if (startAt != null && startAt > Duration.zero) {
        await _player.seek(startAt);
      }
    } catch (e) {
      debugPrint('Error abriendo ${song.title}: $e');
    } finally {
      if (gen == _openGen) {
        _resolving = false;
        notifyListeners();
      }
    }
    if (gen != _openGen) return;
    // Tareas en segundo plano (no bloquean la reproducción):
    unawaited(_prefetchNext());
    unawaited(_maybeExtendRadio());
    _saveState();
  }

  /// En modo radio, descarta las pistas ya reproducidas más allá de la ventana
  /// para que la cola no crezca sin límite. Canoniza a orden de reproducción
  /// (no aplica con shuffle, para no romper el barajado).
  void _trimHistory() {
    if (!_radioEnabled || _shuffle) return;
    if (_orderPos <= _radioHistoryWindow) return;
    final ordered = _order.map((i) => _queue[i]).toList();
    final drop = _orderPos - _radioHistoryWindow;
    final trimmed = ordered.sublist(drop);
    _queue
      ..clear()
      ..addAll(trimmed);
    _order = List<int>.generate(_queue.length, (i) => i);
    _orderPos -= drop;
  }

  Future<Media> _resolveMedia(Song song) async {
    if (song.filePath.isNotEmpty && File(song.filePath).existsSync()) {
      return Media(song.filePath);
    }
    // streaming de YouTube: las URLs del cliente ANDROID_VR no exigen UA,
    // así que mpv las abre directamente sin headers personalizados.
    final url = await _youtube.getStreamUrl(song.id);
    return Media(url);
  }

  /// Pre-resuelve la URL de la siguiente pista de streaming para que el cambio
  /// sea casi instantáneo (la URL queda en la caché de YoutubeService).
  Future<void> _prefetchNext() async {
    if (_orderPos < 0 || _orderPos + 1 >= _order.length) return;
    final song = _queue[_order[_orderPos + 1]];
    if (song.filePath.isNotEmpty) return; // local: no requiere red
    try {
      await _youtube.getStreamUrl(song.id);
    } catch (_) {/* prefetch best-effort */}
  }

  /// Descarga oportunista a disco de la canción de streaming **escuchada** (no
  /// al abrir, para no descargar lo que el usuario salta). Idempotente por
  /// canción. Pasa por DownloadManager (dedup + UI consistente).
  void _maybeCacheCurrent() {
    if (!autoCacheStreaming) return;
    final song = current;
    if (song == null || song.filePath.isNotEmpty || !song.isYoutube) return;
    if (!_cacheRequested.add(song.id)) return; // ya pedida
    _downloads?.enqueue(song.id, song.title, song.author,
        thumbnailUrl: song.thumbnailUrl ?? '');
  }

  /// Recupera la reproducción tras un error de mpv (típicamente URL expirada o
  /// 403): re-resuelve una vez con la URL fresca; si vuelve a fallar, salta.
  Future<void> _recoverFromError() async {
    final song = current;
    if (song == null || song.filePath.isNotEmpty) return; // solo streaming
    if (_recoveryAttempted.contains(song.id)) {
      await next(auto: true); // ya reintentamos: saltar a la siguiente
      return;
    }
    _recoveryAttempted.add(song.id);
    final gen = ++_openGen;
    try {
      final url = await _youtube.getStreamUrl(song.id, forceRefresh: true);
      if (gen != _openGen || current?.id != song.id) return;
      await _player.open(Media(url), play: true);
    } catch (_) {
      await next(auto: true);
    }
  }

  void _onCompleted() {
    _maybeCacheCurrent(); // canciones cortas (<umbral) igual se cachean al terminar
    next(auto: true);
  }

  // ---------------------------------------------------------------------------
  // Persistencia (cola + posición + modos)
  // ---------------------------------------------------------------------------

  /// Guarda el estado de forma diferida (coalesce de ráfagas) en SharedPreferences.
  void _saveState() {
    final prefs = _prefs;
    if (prefs == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      final data = {
        'queue': _queue.map((s) => s.toJson()).toList(),
        'order': _order,
        'orderPos': _orderPos,
        'shuffle': _shuffle,
        'repeat': _repeat.index,
        'radio': _radioEnabled,
        'positionMs': _position.inMilliseconds,
      };
      prefs.setString(_kStateKey, jsonEncode(data));
    });
  }

  /// Restaura la última cola/posición/modos al iniciar la app. Abre la pista en
  /// PAUSA en su posición guardada (no reproduce solo ni descarga en arranque).
  Future<void> restore() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = prefs.getString(_kStateKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final songs = (data['queue'] as List)
          .map((j) => Song.fromJson((j as Map).cast<String, dynamic>()))
          .toList();
      if (songs.isEmpty) return;
      _queue
        ..clear()
        ..addAll(songs);
      _order = (data['order'] as List?)?.cast<int>() ??
          List<int>.generate(_queue.length, (i) => i);
      _orderPos = (data['orderPos'] as int?) ?? 0;
      _shuffle = (data['shuffle'] as bool?) ?? false;
      _repeat = RepeatMode.values[(data['repeat'] as int?) ?? 0];
      _radioEnabled = (data['radio'] as bool?) ?? false;
      final posMs = (data['positionMs'] as int?) ?? 0;
      // sanear inconsistencias
      if (_order.length != _queue.length ||
          _orderPos < 0 ||
          _orderPos >= _order.length) {
        _order = List<int>.generate(_queue.length, (i) => i);
        _orderPos = _orderPos.clamp(0, _queue.length - 1);
      }
      notifyListeners();
      await _openCurrent(
          autoplay: false, startAt: Duration(milliseconds: posMs));
    } catch (e) {
      debugPrint('No se pudo restaurar el estado del reproductor: $e');
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
