// Verifica qué User-Agent acepta googlevideo para la URL de stream.
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonora/services/library_service.dart';
import 'package:sonora/services/youtube_service.dart';

const uaChrome =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
const uaAndroid = 'com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip';

Future<int> probe(String url, String? ua) async {
  final headers = {'Range': 'bytes=0-1024', if (ua != null) 'User-Agent': ua};
  final resp = await http.get(Uri.parse(url), headers: headers);
  return resp.statusCode;
}

void main() {
  test('UA correcto para el stream', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final yt = YoutubeService(LibraryService(prefs));

    final results = await yt.search('coldplay yellow');
    final url = await yt.getStreamUrl(results.first.videoId);
    final client = RegExp(r'[?&]c=([A-Z_]+)').firstMatch(url)?.group(1);
    // ignore: avoid_print
    print('cliente de la URL: c=$client');

    final none = await probe(url, null);
    final chrome = await probe(url, uaChrome);
    final android = await probe(url, uaAndroid);
    // ignore: avoid_print
    print('status -> sin-UA:$none  chrome:$chrome  android:$android');

    yt.dispose();
  }, timeout: const Timeout(Duration(seconds: 90)));
}
