import 'dart:io';

import 'package:flutter/services.dart';

import 'player_service.dart';

/// Conecta las teclas multimedia del sistema (Play/Pause, Next, Previous, Stop)
/// y el panel "Now Playing" del SO con [PlayerService].
///
/// Por ahora activo en macOS (vía MPRemoteCommandCenter/MPNowPlayingInfoCenter
/// en el lado nativo). En otras plataformas no hace nada (no rompe el build).
class MediaKeys {
  MediaKeys(this._player);

  static const _channel = MethodChannel('sonora/media');
  final PlayerService _player;

  String? _lastId;
  int _lastDurationMs = -1;
  bool? _lastPlaying;

  void attach() {
    if (!Platform.isMacOS) return;

    // Comandos del sistema -> reproductor.
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          await _player.play();
        case 'pause':
          await _player.pause();
        case 'playpause':
          await _player.togglePlay();
        case 'next':
          await _player.next();
        case 'previous':
          await _player.previous();
        case 'stop':
          await _player.pause();
      }
      return null;
    });

    // Reproductor -> panel del sistema.
    _player.addListener(_push);
    _push();
  }

  void _push() {
    final song = _player.current;
    if (song == null) {
      if (_lastId != null) {
        _lastId = null;
        _lastPlaying = null;
        _lastDurationMs = -1;
        _channel.invokeMethod('clear');
      }
      return;
    }

    final durMs = _player.duration.inMilliseconds;
    final playing = _player.playing;

    // Metadata completa al cambiar de canción o cuando llega la duración.
    if (song.id != _lastId || durMs != _lastDurationMs) {
      _lastId = song.id;
      _lastDurationMs = durMs;
      _lastPlaying = playing;
      _channel.invokeMethod('updateNowPlaying', {
        'title': song.title,
        'artist': song.author,
        'durationMs': durMs,
        'positionMs': _player.position.inMilliseconds,
        'isPlaying': playing,
        'artworkPath': song.thumbnailPath ?? '',
      });
      return;
    }

    // Solo cambió play/pausa: actualizar estado + posición.
    if (playing != _lastPlaying) {
      _lastPlaying = playing;
      _channel.invokeMethod('updatePlaybackState', {
        'isPlaying': playing,
        'positionMs': _player.position.inMilliseconds,
      });
    }
  }

  void dispose() {
    if (Platform.isMacOS) _player.removeListener(_push);
  }
}
