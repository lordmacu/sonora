import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/playlist.dart';
import '../../services/player_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../widgets/artwork.dart';

class PlaylistsView extends StatelessWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
          child: Row(
            children: [
              Text(l10n.yourPlaylists,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.newButton),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 230,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: app.playlists.length,
            itemBuilder: (_, i) {
              final pl = app.playlists[i];
              return _PlaylistCard(playlist: pl);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(l10n.newPlaylist, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: l10n.playlistNameHint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(l10n.create)),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final pl = await app.playlistService.create(name.trim());
    await app.refreshPlaylists();
    app.openPlaylist(pl.id);
  }
}

class _PlaylistCard extends StatefulWidget {
  const _PlaylistCard({required this.playlist});
  final Playlist playlist;

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l10n = AppLocalizations.of(context);
    final pl = widget.playlist;
    final count = app.resolvedCountOf(pl.id);
    final icon = pl.id == Playlist.favoritesId
        ? Icons.favorite
        : pl.id == Playlist.generalId
            ? Icons.queue_music
            : Icons.playlist_play;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => app.openPlaylist(pl.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hover ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PlaylistCover(
                    images: app.coverImagesOf(pl.id),
                    fallbackIcon: icon,
                    height: 140,
                  ),
                  if (_hover && !pl.isProtected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: PopupMenuButton<String>(
                          color: AppColors.surfaceElevated,
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white, size: 20),
                          tooltip: l10n.options,
                          onSelected: (v) {
                            if (v == 'delete') _confirmDelete(context, pl);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                    leading: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                    title: Text(l10n.deletePlaylist,
                                        style: const TextStyle(
                                            color: Colors.redAccent)))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(playlistDisplayName(l10n, pl),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(l10n.songsCount(count),
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Playlist pl) async {
    final app = context.read<AppState>();
    final player = context.read<PlayerService>();
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(l10n.deletePlaylist,
            style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deletePlaylistBody(pl.name),
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
    // Quitar del reproductor las canciones de esta lista (oculta el player si
    // la que sonaba estaba aquí).
    for (final id in app.playlistService.songIdsOf(pl.id)) {
      player.removeFromQueueById(id);
    }
    await app.playlistService.delete(pl.id);
    await app.refreshPlaylists();
  }
}
