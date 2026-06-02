import 'dart:io';

import 'package:anni_mpris_service/anni_mpris_service.dart' as mpris;
import 'package:flutter/services.dart';
import 'package:smtc_windows/smtc_windows.dart' as smtc;

import 'player_service.dart';

/// Acciones que el reproductor puede ejecutar al recibir teclas multimedia.
class _Handlers {
  _Handlers({
    required this.play,
    required this.pause,
    required this.playPause,
    required this.next,
    required this.previous,
    required this.stop,
  });
  final Future<void> Function() play, pause, playPause, next, previous, stop;
}

/// Conecta las teclas multimedia del sistema (Play/Pause, Next, Previous, Stop)
/// y el panel "Now Playing" del SO con [PlayerService]:
/// - macOS: MPRemoteCommandCenter/MPNowPlayingInfoCenter (vía MethodChannel).
/// - Windows: System Media Transport Controls (smtc_windows).
/// - Linux: MPRIS sobre D-Bus (anni_mpris_service).
class MediaKeys {
  MediaKeys(this._player);

  final PlayerService _player;
  _Backend? _backend;

  String? _lastId;
  int _lastDurationMs = -1;
  bool? _lastPlaying;

  Future<void> attach() async {
    if (Platform.isMacOS) {
      _backend = _MacBackend();
    } else if (Platform.isWindows) {
      _backend = _WindowsBackend();
    } else if (Platform.isLinux) {
      _backend = _LinuxBackend();
    }
    final b = _backend;
    if (b == null) return;

    await b.init(_Handlers(
      play: _player.play,
      pause: _player.pause,
      playPause: _player.togglePlay,
      next: () => _player.next(),
      previous: _player.previous,
      stop: _player.pause,
    ));

    _player.addListener(_push);
    _push();
  }

  void _push() {
    final b = _backend;
    if (b == null) return;
    final song = _player.current;

    if (song == null) {
      if (_lastId != null) {
        _lastId = null;
        _lastPlaying = null;
        _lastDurationMs = -1;
        b.clear();
      }
      return;
    }

    final durMs = _player.duration.inMilliseconds;
    final playing = _player.playing;
    final path = song.thumbnailPath ?? '';
    final uri = path.isNotEmpty
        ? 'file://$path'
        : (song.thumbnailUrl ?? '');

    if (song.id != _lastId || durMs != _lastDurationMs) {
      _lastId = song.id;
      _lastDurationMs = durMs;
      _lastPlaying = playing;
      b.setMetadata(
        title: song.title,
        artist: song.author,
        artworkPath: path,
        artworkUri: uri,
        durationMs: durMs,
        positionMs: _player.position.inMilliseconds,
        playing: playing,
      );
    } else if (playing != _lastPlaying) {
      _lastPlaying = playing;
      b.setPlayback(playing: playing, positionMs: _player.position.inMilliseconds);
    }
  }

  void dispose() {
    _player.removeListener(_push);
    _backend?.dispose();
  }
}

// ---------------------------------------------------------------------------
// Backends por plataforma
// ---------------------------------------------------------------------------

abstract class _Backend {
  Future<void> init(_Handlers h);
  void setMetadata({
    required String title,
    required String artist,
    required String artworkPath,
    required String artworkUri,
    required int durationMs,
    required int positionMs,
    required bool playing,
  });
  void setPlayback({required bool playing, required int positionMs});
  void clear();
  void dispose();
}

/// macOS — MPRemoteCommandCenter + MPNowPlayingInfoCenter (lado nativo Swift).
class _MacBackend implements _Backend {
  static const _channel = MethodChannel('sonora/media');

  @override
  Future<void> init(_Handlers h) async {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          await h.play();
        case 'pause':
          await h.pause();
        case 'playpause':
          await h.playPause();
        case 'next':
          await h.next();
        case 'previous':
          await h.previous();
        case 'stop':
          await h.stop();
      }
      return null;
    });
  }

  @override
  void setMetadata({
    required String title,
    required String artist,
    required String artworkPath,
    required String artworkUri,
    required int durationMs,
    required int positionMs,
    required bool playing,
  }) {
    _channel.invokeMethod('updateNowPlaying', {
      'title': title,
      'artist': artist,
      'artworkPath': artworkPath,
      'durationMs': durationMs,
      'positionMs': positionMs,
      'isPlaying': playing,
    });
  }

  @override
  void setPlayback({required bool playing, required int positionMs}) {
    _channel.invokeMethod('updatePlaybackState', {
      'isPlaying': playing,
      'positionMs': positionMs,
    });
  }

  @override
  void clear() => _channel.invokeMethod('clear');

  @override
  void dispose() {}
}

/// Windows — System Media Transport Controls.
class _WindowsBackend implements _Backend {
  smtc.SMTCWindows? _smtc;

  @override
  Future<void> init(_Handlers h) async {
    await smtc.SMTCWindows.initialize();
    final s = smtc.SMTCWindows(
      enabled: true,
      config: const smtc.SMTCConfig(
        playEnabled: true,
        pauseEnabled: true,
        stopEnabled: true,
        nextEnabled: true,
        prevEnabled: true,
        fastForwardEnabled: false,
        rewindEnabled: false,
      ),
    );
    s.buttonPressStream.listen((button) {
      switch (button) {
        case smtc.PressedButton.play:
          h.play();
        case smtc.PressedButton.pause:
          h.pause();
        case smtc.PressedButton.next:
          h.next();
        case smtc.PressedButton.previous:
          h.previous();
        case smtc.PressedButton.stop:
          h.stop();
        default:
          break;
      }
    });
    _smtc = s;
  }

  @override
  void setMetadata({
    required String title,
    required String artist,
    required String artworkPath,
    required String artworkUri,
    required int durationMs,
    required int positionMs,
    required bool playing,
  }) {
    _smtc?.updateMetadata(smtc.MusicMetadata(
      title: title,
      artist: artist,
      thumbnail: artworkUri.isEmpty ? null : artworkUri,
    ));
    _smtc?.setPlaybackStatus(
        playing ? smtc.PlaybackStatus.playing : smtc.PlaybackStatus.paused);
  }

  @override
  void setPlayback({required bool playing, required int positionMs}) {
    _smtc?.setPlaybackStatus(
        playing ? smtc.PlaybackStatus.playing : smtc.PlaybackStatus.paused);
  }

  @override
  void clear() {
    _smtc?.setPlaybackStatus(smtc.PlaybackStatus.stopped);
    _smtc?.clearMetadata();
  }

  @override
  void dispose() => _smtc?.dispose();
}

/// Linux — MPRIS sobre D-Bus.
class _LinuxBackend implements _Backend {
  _SonoraMpris? _mpris;
  int _trackCounter = 0;

  @override
  Future<void> init(_Handlers h) async {
    _mpris = _SonoraMpris(h);
  }

  @override
  void setMetadata({
    required String title,
    required String artist,
    required String artworkPath,
    required String artworkUri,
    required int durationMs,
    required int positionMs,
    required bool playing,
  }) {
    final m = _mpris;
    if (m == null) return;
    m.metadata = mpris.Metadata(
      trackId: '/co/cristiangarcia/sonora/track/${_trackCounter++}',
      trackTitle: title,
      trackArtist: artist.isEmpty ? null : [artist],
      trackLength: durationMs > 0 ? Duration(milliseconds: durationMs) : null,
      artUrl: artworkUri.isEmpty ? null : artworkUri,
    );
    m.playbackStatus =
        playing ? mpris.PlaybackStatus.playing : mpris.PlaybackStatus.paused;
  }

  @override
  void setPlayback({required bool playing, required int positionMs}) {
    _mpris?.playbackStatus =
        playing ? mpris.PlaybackStatus.playing : mpris.PlaybackStatus.paused;
  }

  @override
  void clear() => _mpris?.playbackStatus = mpris.PlaybackStatus.stopped;

  @override
  void dispose() => _mpris?.dispose();
}

class _SonoraMpris extends mpris.MPRISService {
  _SonoraMpris(this._h)
      : super(
          'sonora',
          identity: 'Sonora',
          desktopEntry: 'sonora',
          // supportLoopStatus=true es necesario para que el setter de metadata
          // del paquete emita los cambios (limitación conocida de la lib).
          supportLoopStatus: true,
        );

  final _Handlers _h;

  @override
  Future<void> onPlay() => _h.play();
  @override
  Future<void> onPause() => _h.pause();
  @override
  Future<void> onPlayPause() => _h.playPause();
  @override
  Future<void> onNext() => _h.next();
  @override
  Future<void> onPrevious() => _h.previous();
  @override
  Future<void> onStop() => _h.stop();
}
