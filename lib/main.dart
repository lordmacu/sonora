import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'services/download_manager.dart';
import 'services/library_service.dart';
import 'services/playlist_service.dart';
import 'services/player_service.dart';
import 'services/youtube_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Cargar variables de entorno (.env). Si no existe, seguimos sin romper.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {/* .env opcional */}

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const opts = WindowOptions(
      size: Size(1200, 780),
      minimumSize: Size(900, 620),
      center: true,
      title: 'Sonora',
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final prefs = await SharedPreferences.getInstance();
  final library = LibraryService(prefs);
  final playlistService = PlaylistService(prefs);
  final youtube = YoutubeService(library);
  final downloads = DownloadManager(youtube);
  final player = PlayerService(youtube, downloads: downloads, prefs: prefs);
  final appState = AppState(
    library: library,
    playlistService: playlistService,
    downloads: downloads,
  );
  // restaurar la última cola/posición (en pausa) sin bloquear el arranque
  unawaited(player.restore());

  runApp(SonoraApp(
    appState: appState,
    player: player,
    downloads: downloads,
    youtube: youtube,
    library: library,
    playlistService: playlistService,
  ));
}

class SonoraApp extends StatelessWidget {
  const SonoraApp({
    super.key,
    required this.appState,
    required this.player,
    required this.downloads,
    required this.youtube,
    required this.library,
    required this.playlistService,
  });

  final AppState appState;
  final PlayerService player;
  final DownloadManager downloads;
  final YoutubeService youtube;
  final LibraryService library;
  final PlaylistService playlistService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: player),
        ChangeNotifierProvider.value(value: downloads),
        Provider.value(value: youtube),
        Provider.value(value: library),
        Provider.value(value: playlistService),
      ],
      child: MaterialApp(
        title: 'Sonora',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
