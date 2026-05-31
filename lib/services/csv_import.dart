import 'dart:io';

import '../models/import_track.dart';

/// Lee un CSV exportado de Spotify (formato Exportify / TuneMyMusic).
/// Columnas esperadas: "Track Name", "Artist Name(s)", "Album Name", "Duration (ms)".
class CsvImportService {
  Future<List<ImportTrack>> parseFile(String path) async {
    final lines = await File(path).readAsLines();
    return parseLines(lines);
  }

  List<ImportTrack> parseLines(List<String> lines) {
    if (lines.isEmpty) throw Exception('CSV vacío');
    final header = _parseRow(lines.first);
    int find(List<String> names) =>
        header.indexWhere((c) => names.any((n) => c.trim().toLowerCase() == n));

    final nameIdx = find(['track name', 'name', 'título', 'titulo']);
    final artistIdx = find(['artist name(s)', 'artist', 'artists', 'artista']);
    final albumIdx = find(['album name', 'album', 'álbum']);
    final durIdx = find(['duration (ms)', 'duration']);

    if (nameIdx < 0 || artistIdx < 0) {
      throw Exception("El CSV no tiene columnas 'Track Name' / 'Artist Name(s)'");
    }

    final out = <ImportTrack>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final row = _parseRow(line);
      String at(int idx) => idx >= 0 && idx < row.length ? row[idx].trim() : '';
      final name = at(nameIdx);
      if (name.isEmpty) continue;
      out.add(ImportTrack(
        id: 'csv_$i',
        name: name,
        artists: at(artistIdx),
        albumName: at(albumIdx),
        durationMs: int.tryParse(at(durIdx)) ?? 0,
      ));
    }
    if (out.isEmpty) throw Exception('No se encontraron canciones en el CSV');
    return out;
  }

  List<String> _parseRow(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    result.add(sb.toString());
    return result;
  }
}
