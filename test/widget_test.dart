// Smoke test básico de Sonora.
import 'package:flutter_test/flutter_test.dart';

import 'package:sonora/services/csv_import.dart';

void main() {
  test('CSV de Spotify se parsea correctamente', () {
    final csv = CsvImportService();
    final tracks = csv.parseLines([
      'Track Name,Artist Name(s),Album Name,Duration (ms)',
      'Bohemian Rhapsody,Queen,A Night at the Opera,354000',
      '"Song, with comma","Artist A, Artist B",Album,200000',
    ]);
    expect(tracks.length, 2);
    expect(tracks[0].name, 'Bohemian Rhapsody');
    expect(tracks[0].artists, 'Queen');
    expect(tracks[1].name, 'Song, with comma');
    expect(tracks[1].artists, 'Artist A, Artist B');
  });
}
