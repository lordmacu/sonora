import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/playlist.dart';
import '../../services/player_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../widgets/artwork.dart';
import '../widgets/song_row.dart';

class PlaylistDetailView extends StatelessWidget {
  const PlaylistDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final player = context.read<PlayerService>();
    final l10n = AppLocalizations.of(context);
    final id = app.currentPlaylistId;
    if (id == null) return const SizedBox();
    final pl = app.playlistById(id);
    if (pl == null) return const SizedBox();
    final songs = app.songsOfPlaylist(id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // cabecera
        Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PlaylistCover(
                images: app.coverImagesOf(id),
                fallbackIcon:
                    pl.id == Playlist.favoritesId ? Icons.favorite : Icons.queue_music,
                width: 120,
                height: 120,
                radius: 8,
                iconSize: 56,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(l10n.playlistLabel,
                        style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(playlistDisplayName(l10n, pl),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(l10n.songsCount(songs.length),
                        style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (!pl.isProtected)
                PopupMenuButton<String>(
                  color: AppColors.surfaceElevated,
                  icon: const Icon(Icons.more_horiz, color: AppColors.onSurfaceVariant),
                  onSelected: (v) async {
                    if (v == 'rename') {
                      await _rename(context, pl);
                    } else if (v == 'delete') {
                      await _delete(context, pl);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                    PopupMenuItem(value: 'delete', child: Text(l10n.deletePlaylist)),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              if (songs.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => player.playSongs(songs),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.play),
                ),
              const SizedBox(width: 12),
              if (songs.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    player.toggleShuffle();
                    player.playSongs(songs);
                  },
                  icon: const Icon(Icons.shuffle),
                  label: Text(l10n.shuffle),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: songs.isEmpty
              ? Center(
                  child: Text(l10n.emptyPlaylist,
                      style: const TextStyle(color: AppColors.onSurfaceVariant)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: songs.length,
                  itemBuilder: (_, i) => SongRow(
                    song: songs[i],
                    index: i,
                    onPlay: () => player.playSongs(songs, startIndex: i),
                    onRemoveFromPlaylist: () =>
                        _removeFromPlaylist(context, id, songs[i].id),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context, Playlist pl) async {
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: pl.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(l10n.renamePlaylist, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(l10n.save)),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await app.playlistService.rename(pl.id, name.trim());
    await app.refreshPlaylists();
  }

  Future<void> _delete(BuildContext context, Playlist pl) async {
    final app = context.read<AppState>();
    final player = context.read<PlayerService>();
    final l10n = AppLocalizations.of(context);
    final count = app.resolvedCountOf(pl.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(l10n.deletePlaylist,
            style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deletePlaylistDetailBody(pl.name, count),
            style: const TextStyle(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    for (final id in app.playlistService.songIdsOf(pl.id)) {
      player.removeFromQueueById(id);
    }
    await app.playlistService.delete(pl.id);
    await app.refreshPlaylists();
    app.go(AppView.playlists);
  }

  Future<void> _removeFromPlaylist(
      BuildContext context, String playlistId, String videoId) async {
    final app = context.read<AppState>();
    // Si la canción se está reproduciendo, quitarla también del reproductor.
    context.read<PlayerService>().removeFromQueueById(videoId);
    await app.playlistService.removeSong(playlistId, videoId);
    await app.refreshPlaylists();
  }
}
