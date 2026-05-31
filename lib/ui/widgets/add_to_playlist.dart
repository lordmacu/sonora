import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

/// Hoja inferior reutilizable para agregar una canción a una playlist.
/// Se usa desde el reproductor inferior, la búsqueda y la pantalla de la canción.
Future<void> showAddToPlaylistSheet(BuildContext context, Song song) async {
  final app = context.read<AppState>();
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      Future<void> add(String playlistId, String name) async {
        await app.addSongToPlaylist(playlistId, song);
        if (ctx.mounted) Navigator.pop(ctx);
        messenger.showSnackBar(SnackBar(content: Text(l10n.addedTo(name))));
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Text(l10n.addToPlaylist,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Flexible(
                    child: Text(song.title,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 12)),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: Text(l10n.newPlaylist,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              onTap: () async {
                final name = await _promptName(ctx);
                if (name == null || name.trim().isEmpty) return;
                final pl = await app.createPlaylist(name.trim());
                await add(pl.id, name.trim());
              },
            ),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final pl in app.playlists)
                    ListTile(
                      leading: Icon(
                        pl.id == Playlist.favoritesId
                            ? Icons.favorite
                            : Icons.queue_music,
                        color: AppColors.onSurfaceVariant,
                      ),
                      title: Text(playlistDisplayName(l10n, pl),
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                          l10n.songsCount(app.playlistService.songCount(pl.id)),
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 12)),
                      onTap: () => add(pl.id, playlistDisplayName(l10n, pl)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<String?> _promptName(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController();
  return showDialog<String>(
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
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(l10n.create)),
      ],
    ),
  );
}
