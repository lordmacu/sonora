import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/playlist.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../widgets/artwork.dart';

class PlaylistsView extends StatelessWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
          child: Row(
            children: [
              const Text('Tus playlists',
                  style: TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva'),
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
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Nueva playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Nombre'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Crear')),
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
    final pl = widget.playlist;
    final count = app.resolvedCountOf(pl.id);
    final icon = pl.id == Playlist.favoritesId
        ? Icons.favorite
        : pl.id == Playlist.generalId
            ? Icons.queue_music
            : Icons.playlist_play;
    final cover = app.firstSongOf(pl.id);

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
              PlaylistCover(
                localPath: cover?.thumbnailPath,
                url: cover?.thumbnailUrl,
                fallbackIcon: icon,
                height: 140,
              ),
              const SizedBox(height: 10),
              Text(pl.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('$count canciones',
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
