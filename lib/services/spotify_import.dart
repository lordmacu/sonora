import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/import_track.dart';

class SpotifyPlaylist {
  SpotifyPlaylist(this.name, this.tracks);
  final String name;
  final List<ImportTrack> tracks;
}

/// Importa playlists, álbumes o canciones de Spotify **sin API ni login**,
/// leyendo el JSON incrustado (`__NEXT_DATA__`) de la página `embed` pública.
/// Funciona también con playlists editoriales/algorítmicas (37i9…), que la API
/// oficial bloquea. Devuelve [ImportTrack] para reutilizar el flujo de
/// búsqueda+descarga del CSV.
class SpotifyImportService {
  final http.Client _http = http.Client();

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// Devuelve `(type, id)` a partir de una URL/URI de Spotify.
  ({String type, String id})? _parse(String input) {
    final s = input.trim();
    final uri = RegExp(r'^spotify:(playlist|track|album):([A-Za-z0-9]+)')
        .firstMatch(s);
    if (uri != null) return (type: uri.group(1)!, id: uri.group(2)!);
    final url =
        RegExp(r'open\.spotify\.com/(?:embed/)?(playlist|track|album)/([A-Za-z0-9]+)')
            .firstMatch(s);
    if (url != null) return (type: url.group(1)!, id: url.group(2)!);
    return null;
  }

  Future<SpotifyPlaylist> fetchFromUrl(String input) async {
    final res = _parse(input);
    if (res == null) {
      throw Exception(
          'Enlace de Spotify no válido. Pega una playlist, álbum o canción.');
    }

    final embedUrl = 'https://open.spotify.com/embed/${res.type}/${res.id}';
    final resp = await _http.get(Uri.parse(embedUrl), headers: {
      'User-Agent': _ua,
      'Accept-Language': 'es,en;q=0.8',
    });
    debugPrint('Spotify embed GET ${resp.statusCode} $embedUrl');
    if (resp.statusCode != 200) {
      throw Exception(
          'No se pudo abrir la página de Spotify (${resp.statusCode}). ¿El enlace es correcto y es contenido público?');
    }

    final data = _extractNextData(resp.body);

    // Ruta conocida; si cambia el formato, caemos a una búsqueda recursiva.
    var entity = _dig(data, ['props', 'pageProps', 'state', 'data', 'entity']);
    entity ??= _findMapWith(data, 'trackList');

    final name = (entity is Map
            ? (entity['name'] ?? entity['title'])
            : null)
        ?.toString() ??
        'Spotify';

    final rawList = (entity is Map ? entity['trackList'] : null) ??
        _findFirstList(data, 'trackList');

    final tracks = <ImportTrack>[];
    var idx = 0;
    if (rawList is List) {
      for (final item in rawList) {
        final t = _trackFromEmbed(item, idx);
        if (t != null) {
          tracks.add(t);
          idx++;
        }
      }
    }
    // Canción suelta sin trackList: construir desde la propia entidad.
    if (tracks.isEmpty && entity is Map) {
      final t = _trackFromEmbed(entity, 0);
      if (t != null) tracks.add(t);
    }

    if (tracks.isEmpty) {
      throw Exception('No se encontraron canciones en ese enlace de Spotify.');
    }
    debugPrint('Spotify embed: ${tracks.length} canciones de "$name"');
    return SpotifyPlaylist(name, tracks);
  }

  /// Busca recursivamente la primera lista no vacía guardada bajo [key].
  static dynamic _findFirstList(dynamic node, String key) {
    if (node is Map) {
      final v = node[key];
      if (v is List && v.isNotEmpty) return v;
      for (final value in node.values) {
        final found = _findFirstList(value, key);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findFirstList(item, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Busca recursivamente el primer Map que contenga [key].
  static Map? _findMapWith(dynamic node, String key) {
    if (node is Map) {
      if (node.containsKey(key)) return node;
      for (final value in node.values) {
        final found = _findMapWith(value, key);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findMapWith(item, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Extrae y parsea el JSON del <script id="__NEXT_DATA__"> de la página embed.
  Map<String, dynamic> _extractNextData(String html) {
    final match = RegExp(
      r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>',
      dotAll: true,
    ).firstMatch(html);
    if (match == null) {
      throw Exception(
          'Spotify no devolvió datos legibles (posible bloqueo o cambio de formato).');
    }
    return jsonDecode(match.group(1)!) as Map<String, dynamic>;
  }

  ImportTrack? _trackFromEmbed(dynamic item, int idx) {
    if (item is! Map) return null;
    final title = (item['title'] ?? item['name'])?.toString() ?? '';
    if (title.isEmpty) return null;

    // Artistas: `subtitle` (string) o `artists` (lista de {name}).
    var artists = (item['subtitle'] as String?)?.trim() ?? '';
    if (artists.isEmpty && item['artists'] is List) {
      artists = (item['artists'] as List)
          .map((a) => a is Map ? a['name']?.toString() : null)
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .join(', ');
    }

    final uri = item['uri']?.toString() ?? '';
    final id = uri.contains(':') ? uri.split(':').last : 'sp_$idx';
    final duration = (item['duration'] as num?)?.toInt() ?? 0;

    return ImportTrack(
      id: id,
      name: title,
      artists: artists,
      durationMs: duration,
    );
  }

  static dynamic _dig(dynamic node, List<String> path) {
    dynamic cur = node;
    for (final key in path) {
      if (cur is Map && cur.containsKey(key)) {
        cur = cur[key];
      } else {
        return null;
      }
    }
    return cur;
  }

  void dispose() => _http.close();
}
