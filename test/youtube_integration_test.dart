// Test de integración (requiere red). Verifica que la búsqueda en YouTube Music
// y la extracción de URL de stream funcionan end-to-end.
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonora/services/library_service.dart';
import 'package:sonora/services/youtube_service.dart';

void main() {
  test('búsqueda + stream de YouTube', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final yt = YoutubeService(LibraryService(prefs));

    final results = await yt.search('bohemian rhapsody queen');
    expect(results, isNotEmpty, reason: 'la búsqueda debe devolver resultados');
    final first = results.first;
    expect(first.videoId, isNotEmpty);
    // ignore: avoid_print
    print('Encontrado: ${first.title} - ${first.author} (${first.videoId})');

    final url = await yt.getStreamUrl(first.videoId);
    expect(url, startsWith('http'));
    // ignore: avoid_print
    print('Stream URL OK (${url.length} chars)');

    yt.dispose();
  }, timeout: const Timeout(Duration(seconds: 90)));
}
