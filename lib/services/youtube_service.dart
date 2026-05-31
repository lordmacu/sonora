import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../models/youtube_result.dart';
import 'library_service.dart';

class DownloadProgress {
  final double progress; // 0..1
  final int downloaded;
  final int total;
  const DownloadProgress(this.progress, this.downloaded, this.total);
}

/// Búsqueda en YouTube Music (InnerTube WEB_REMIX), extracción de streams,
/// descarga de audio con progreso, cola de radio y relacionados.
/// Equivalente a YoutubeRepository.kt.
class YoutubeService {
  YoutubeService(this._library);

  final LibraryService _library;
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  final http.Client _http = http.Client();

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  // ---------------------------------------------------------------------------
  // Búsqueda
  // ---------------------------------------------------------------------------

  Future<List<YoutubeResult>> search(String query) async {
    try {
      final results = await _searchYtMusic(query);
      if (results.isNotEmpty) return results;
    } catch (_) {/* fallback */}
    return _searchFallback(query);
  }

  Future<List<YoutubeResult>> _searchYtMusic(String query) async {
    final payload = jsonEncode({
      'context': {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': '1.20260114.03.00',
          'hl': 'es',
          'gl': 'CO',
        }
      },
      'query': query,
      'params': 'EgWKAQIIAWoKEAoQAxAEEAkQBQ==',
    });

    final resp = await _http.post(
      Uri.parse('https://music.youtube.com/youtubei/v1/search?prettyPrint=false'),
      headers: {
        'User-Agent': _ua,
        'Origin': 'https://music.youtube.com',
        'Referer': 'https://music.youtube.com/search',
        'X-YouTube-Client-Name': '67',
        'X-YouTube-Client-Version': '1.20260114.03.00',
        'Content-Type': 'application/json',
      },
      body: payload,
    );
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body) as Map<String, dynamic>;

    final out = <YoutubeResult>[];
    final tabs = _dig(json, [
      'contents',
      'tabbedSearchResultsRenderer',
      'tabs',
    ]) as List?;
    for (final tab in tabs ?? const []) {
      final sections = _dig(tab as Map<String, dynamic>, [
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
      ]) as List?;
      for (final section in sections ?? const []) {
        final shelf = (section as Map<String, dynamic>)['musicShelfRenderer'];
        if (shelf is Map<String, dynamic>) {
          _parseShelfItems(shelf['contents'] as List?, out);
        }
      }
    }
    return out;
  }

  void _parseShelfItems(List? items, List<YoutubeResult> out) {
    for (final item in items ?? const []) {
      final r = (item as Map<String, dynamic>)['musicResponsiveListItemRenderer'];
      if (r is! Map<String, dynamic>) continue;

      final videoId = _dig(r, [
        'overlay',
        'musicItemThumbnailOverlayRenderer',
        'content',
        'musicPlayButtonRenderer',
        'playNavigationEndpoint',
        'watchEndpoint',
        'videoId',
      ]) as String?;
      if (videoId == null || videoId.isEmpty) continue;

      final flexCols = r['flexColumns'] as List?;
      String flexText(int i) {
        if (flexCols == null || i >= flexCols.length) return '';
        return (_dig(flexCols[i] as Map<String, dynamic>, [
              'musicResponsiveListItemFlexColumnRenderer',
              'text',
              'runs',
              0,
              'text',
            ]) as String?) ??
            '';
      }

      final title = flexText(0);
      if (title.isEmpty) continue;
      final artist = flexText(1);

      final thumbs = _dig(r, [
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]) as List?;
      final thumb = _bestThumb(thumbs);

      String durationText = (_dig(r, [
            'fixedColumns',
            0,
            'musicResponsiveListItemFixedColumnRenderer',
            'text',
            'runs',
            0,
            'text',
          ]) as String?) ??
          flexText(2);

      out.add(YoutubeResult(
        videoId: videoId,
        title: title,
        author: artist,
        durationSeconds: _parseDuration(durationText),
        thumbnailUrl: thumb,
      ));
    }
  }

  Future<List<YoutubeResult>> _searchFallback(String query) async {
    final list = await _yt.search.search(query);
    return list.take(10).map((v) {
      return YoutubeResult(
        videoId: v.id.value,
        title: v.title,
        author: v.author,
        durationSeconds: v.duration?.inSeconds ?? 0,
        thumbnailUrl: v.thumbnails.highResUrl,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Radio / relacionados (cola de YouTube, sin IA)
  // ---------------------------------------------------------------------------

  Future<List<YoutubeResult>> getRadioQueue(String videoId, {int maxItems = 25}) async {
    final payload = jsonEncode({
      'context': {
        'client': {
          'clientName': 'WEB',
          'clientVersion': '2.20240101.00.00',
          'hl': 'es',
          'gl': 'CO',
        }
      },
      'videoId': videoId,
      'playlistId': 'RD$videoId',
    });
    final resp = await _http.post(
      Uri.parse('https://www.youtube.com/youtubei/v1/next?prettyPrint=false'),
      headers: {
        'User-Agent': _ua,
        'X-YouTube-Client-Name': '1',
        'X-YouTube-Client-Version': '2.20240101.00.00',
        'Origin': 'https://www.youtube.com',
        'Referer': 'https://www.youtube.com/watch?v=$videoId',
        'Content-Type': 'application/json',
      },
      body: payload,
    );
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final contents = _dig(json, [
      'contents',
      'twoColumnWatchNextResults',
      'playlist',
      'playlist',
      'contents',
    ]) as List?;
    final out = <YoutubeResult>[];
    for (final c in contents ?? const []) {
      if (out.length >= maxItems) break;
      final pvr = (c as Map<String, dynamic>)['playlistPanelVideoRenderer'];
      if (pvr is! Map<String, dynamic>) continue;
      final vid = pvr['videoId'] as String?;
      if (vid == null || vid.isEmpty || vid == videoId) continue;
      final title = (_dig(pvr, ['title', 'runs', 0, 'text']) as String?) ??
          (_dig(pvr, ['title', 'simpleText']) as String?);
      if (title == null) continue;
      final artist = (_dig(pvr, ['longBylineText', 'runs', 0, 'text']) as String?) ?? '';
      final thumbs = _dig(pvr, ['thumbnail', 'thumbnails']) as List?;
      final durText = (_dig(pvr, ['lengthText', 'simpleText']) as String?) ?? '';
      out.add(YoutubeResult(
        videoId: vid,
        title: title,
        author: artist,
        durationSeconds: _parseDuration(durText),
        thumbnailUrl: _bestThumb(thumbs),
      ));
    }
    return out;
  }

  Future<List<YoutubeResult>> getRelated(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      final related = await _yt.videos.getRelatedVideos(video);
      if (related == null) return [];
      return related.take(15).map((v) {
        return YoutubeResult(
          videoId: v.id.value,
          title: v.title,
          author: v.author,
          durationSeconds: v.duration?.inSeconds ?? 0,
          thumbnailUrl: v.thumbnails.highResUrl,
        );
      }).toList();
    } catch (_) {
      return getRadioQueue(videoId, maxItems: 15);
    }
  }

  // ---------------------------------------------------------------------------
  // Stream URL + descarga
  // ---------------------------------------------------------------------------

  final Map<String, _StreamUrl> _urlCache = {};

  /// Devuelve la URL de audio para streaming. Usa el cliente ANDROID_VR porque
  /// sus URLs (`c=ANDROID_VR`) no exigen un User-Agent específico en el CDN de
  /// googlevideo, así que mpv las abre directamente (el cliente `android`
  /// estándar sí exige el UA de la app y termina en 403).
  ///
  /// Cachea la URL respetando su parámetro `expire=`; reusa mientras no esté por
  /// vencer. [forceRefresh] ignora la caché (p. ej. al recuperarse de un 403).
  Future<String> getStreamUrl(String videoId, {bool forceRefresh = false}) async {
    final cached = _urlCache[videoId];
    if (!forceRefresh && cached != null && !cached.isExpiring) {
      return cached.url;
    }
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [yt.YoutubeApiClient.androidVr],
    );
    final url = _pickAudio(manifest).url.toString();
    _urlCache[videoId] = _StreamUrl(url);
    return url;
  }

  /// Prefiere m4a/AAC (más compatible con mpv); si no hay, el de mayor bitrate.
  yt.AudioOnlyStreamInfo _pickAudio(yt.StreamManifest manifest) {
    final mp4 = manifest.audioOnly
        .where((s) => s.container == yt.StreamContainer.mp4)
        .toList();
    if (mp4.isNotEmpty) {
      mp4.sort((a, b) => b.bitrate.compareTo(a.bitrate));
      return mp4.first;
    }
    return manifest.audioOnly.withHighestBitrate();
  }

  /// Descarga el audio de un video y lo guarda en disco. Emite progreso.
  Stream<DownloadProgress> downloadAudio(
    String videoId,
    String title,
    String author, {
    String thumbnailUrl = '',
  }) async* {
    final cached = await _library.cachedPath(videoId);
    if (cached != null) {
      await _downloadThumbIfNeeded(videoId, thumbnailUrl);
      yield const DownloadProgress(1, 0, 0);
      return;
    }

    final dir = await _library.audioDir();
    // ANDROID_VR igual que en streaming: el cliente `android` estándar puede
    // quedar bloqueado en la descarga (se queda en 0%).
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [yt.YoutubeApiClient.androidVr],
    );
    final audio = _pickAudio(manifest);
    final total = audio.size.totalBytes;

    final ext = audio.container.name; // mp4 -> usamos m4a; webm -> webm
    final outExt = ext == 'webm' ? 'webm' : 'm4a';
    final file = File(p.join(dir.path, '$videoId.$outExt'));
    final sink = file.openWrite();

    var downloaded = 0;
    yield DownloadProgress(0, 0, total);
    try {
      await for (final chunk in _yt.videos.streamsClient.get(audio)) {
        sink.add(chunk);
        downloaded += chunk.length;
        yield DownloadProgress(
          total > 0 ? downloaded / total : 0,
          downloaded,
          total,
        );
      }
      await sink.flush();
      await sink.close();
    } catch (e) {
      await sink.close();
      if (file.existsSync()) file.deleteSync();
      rethrow;
    }

    await _library.saveMeta(videoId, title, author);
    await _downloadThumbIfNeeded(videoId, thumbnailUrl);
    yield DownloadProgress(1, downloaded, total);
  }

  Future<void> _downloadThumbIfNeeded(String videoId, String thumbnailUrl) async {
    if (thumbnailUrl.isEmpty) return;
    final dir = await _library.audioDir();
    final thumbFile = File(p.join(dir.path, '$videoId.jpg'));
    if (thumbFile.existsSync() && thumbFile.lengthSync() > 0) return;
    try {
      final resp = await _http.get(Uri.parse(thumbnailUrl));
      if (resp.statusCode == 200) {
        await thumbFile.writeAsBytes(resp.bodyBytes);
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _bestThumb(List? thumbs) {
    if (thumbs == null || thumbs.isEmpty) return '';
    Map<String, dynamic>? best;
    var bestW = -1;
    for (final t in thumbs) {
      final m = t as Map<String, dynamic>;
      final w = (m['width'] as int?) ?? 0;
      if (w > bestW) {
        bestW = w;
        best = m;
      }
    }
    return (best?['url'] as String?) ?? '';
  }

  static int _parseDuration(String text) {
    if (text.isEmpty) return 0;
    final parts = text.split(':').reversed.toList();
    var secs = 0;
    for (var i = 0; i < parts.length; i++) {
      final v = int.tryParse(parts[i].trim()) ?? 0;
      secs += (v * _pow60(i));
    }
    return secs;
  }

  static int _pow60(int exp) {
    var r = 1;
    for (var i = 0; i < exp; i++) {
      r *= 60;
    }
    return r;
  }

  /// Navega un árbol JSON con claves (String) e índices (int), tolerante a nulls.
  static dynamic _dig(dynamic node, List<dynamic> path) {
    dynamic cur = node;
    for (final key in path) {
      if (cur == null) return null;
      if (key is int) {
        if (cur is List && key >= 0 && key < cur.length) {
          cur = cur[key];
        } else {
          return null;
        }
      } else {
        if (cur is Map) {
          cur = cur[key];
        } else {
          return null;
        }
      }
    }
    return cur;
  }

  void dispose() {
    _yt.close();
    _http.close();
  }
}

/// URL de stream cacheada con su expiración (parseada del parámetro `expire=`).
class _StreamUrl {
  _StreamUrl(this.url) : expiresAt = _parseExpiry(url);

  final String url;
  final DateTime expiresAt;

  /// Se considera "por vencer" 5 min antes para re-resolver con margen.
  bool get isExpiring =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  static DateTime _parseExpiry(String url) {
    final exp = Uri.tryParse(url)?.queryParameters['expire'];
    final secs = int.tryParse(exp ?? '');
    if (secs == null) {
      // sin expire conocido: asumimos 1 h de validez
      return DateTime.now().add(const Duration(hours: 1));
    }
    return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
  }
}
