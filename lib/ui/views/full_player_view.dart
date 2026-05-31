import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/song.dart';
import '../../services/player_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/artwork.dart';
import '../widgets/download_button.dart';

class FullPlayerView extends StatelessWidget {
  const FullPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    final song = player.current;

    return Column(
      children: [
        // barra superior
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                color: Colors.white,
                onPressed: () => app.setPlayerExpanded(false),
              ),
              const Spacer(),
              Text(l10n.nowPlaying,
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: song == null
              ? Center(
                  child: Text(l10n.nothingPlaying,
                      style: const TextStyle(color: AppColors.onSurfaceVariant)),
                )
              : Row(
                  children: [
                    // carátula + info
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Artwork(
                              localPath: song.thumbnailPath,
                              url: song.thumbnailUrl,
                              size: 320,
                              radius: 12,
                            ),
                            const SizedBox(height: 28),
                            Text(song.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(song.author,
                                style: const TextStyle(
                                    color: AppColors.onSurfaceVariant, fontSize: 16)),
                            const SizedBox(height: 24),
                            _actions(context, song),
                          ],
                        ),
                      ),
                    ),
                    // cola
                    Container(
                      width: 320,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _QueuePanel(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, Song song) {
    final player = context.watch<PlayerService>();
    final l10n = AppLocalizations.of(context);
    final radioOn = player.radioEnabled;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Toggle de radio (autoplay de relacionados). Relleno cuando está activo,
        // incluso si se activó automáticamente al reproducir una canción suelta.
        radioOn
            ? FilledButton.icon(
                onPressed: player.toggleRadio,
                icon: const Icon(Icons.radio),
                label: Text(l10n.radio),
              )
            : OutlinedButton.icon(
                onPressed: player.toggleRadio,
                icon: const Icon(Icons.radio),
                label: Text(l10n.radio),
              ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => showAddToPlaylistSheet(context, song),
          icon: const Icon(Icons.playlist_add),
          label: Text(l10n.addToList),
        ),
        const SizedBox(width: 12),
        SongDownloadButton(song: song, labeled: true),
      ],
    );
  }
}

class _QueuePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final l10n = AppLocalizations.of(context);
    final queue = player.queue;
    final current = player.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l10n.queue,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: queue.isEmpty
              ? Center(
                  child: Text(l10n.emptyQueue,
                      style: const TextStyle(color: AppColors.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: queue.length,
                  itemBuilder: (_, i) {
                    final s = queue[i];
                    final isCurrent = current?.id == s.id;
                    return ListTile(
                      dense: true,
                      leading: Artwork(
                        localPath: s.thumbnailPath,
                        url: s.thumbnailUrl,
                        size: 40,
                      ),
                      title: Text(s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isCurrent ? AppColors.primary : Colors.white,
                              fontSize: 13)),
                      subtitle: Text(s.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 11)),
                      onTap: () => player.jumpTo(i),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
