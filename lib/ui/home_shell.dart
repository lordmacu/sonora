import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/player_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'now_playing_bar.dart';
import 'sidebar.dart';
import 'views/downloads_view.dart';
import 'views/full_player_view.dart';
import 'views/home_view.dart';
import 'views/import_view.dart';
import 'views/playlist_detail_view.dart';
import 'views/playlists_view.dart';
import 'views/search_view.dart';
import 'views/settings_view.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hasSong = context.select<PlayerService, bool>((p) => p.current != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const Sidebar(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1F1F1F), AppColors.background],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: app.playerExpanded
                        ? const FullPlayerView()
                        : _viewFor(app.view),
                  ),
                ),
              ],
            ),
          ),
          if (hasSong) const NowPlayingBar(),
        ],
      ),
    );
  }

  Widget _viewFor(AppView view) {
    switch (view) {
      case AppView.home:
        return const HomeView();
      case AppView.search:
        return const SearchView();
      case AppView.downloads:
        return const DownloadsView();
      case AppView.playlists:
        return const PlaylistsView();
      case AppView.playlistDetail:
        return const PlaylistDetailView();
      case AppView.import:
        return const ImportView();
      case AppView.settings:
        return const SettingsView();
    }
  }
}
