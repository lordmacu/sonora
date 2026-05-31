import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/song.dart';
import '../../services/player_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'add_to_playlist.dart';
import 'artwork.dart';

/// Fila de canción estilo Spotify: índice/carátula, título, autor, duración,
/// favorito y menú contextual.
class SongRow extends StatefulWidget {
  const SongRow({
    super.key,
    required this.song,
    required this.index,
    required this.onPlay,
    this.trailing,
    this.onMenu,
    this.onDelete,
    this.onRemoveFromPlaylist,
  });

  final Song song;
  final int index;
  final VoidCallback onPlay;
  final Widget? trailing;
  final VoidCallback? onMenu;

  /// Si se provee, el menú de tres puntos muestra "Eliminar" directamente.
  final VoidCallback? onDelete;

  /// Si se provee, el menú muestra "Quitar de la playlist" directamente.
  final VoidCallback? onRemoveFromPlaylist;

  @override
  State<SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<SongRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final app = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);
    final isCurrent = player.current?.id == widget.song.id;
    final isFav = app.isFavorite(widget.song.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onDoubleTap: widget.onPlay,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: _hover
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(isCurrent && player.playing
                            ? Icons.pause
                            : Icons.play_arrow),
                        color: Colors.white,
                        onPressed: widget.onPlay,
                      )
                    : Center(
                        child: isCurrent
                            ? const Icon(Icons.volume_up, size: 16, color: AppColors.primary)
                            : Text(
                                '${widget.index + 1}',
                                style: const TextStyle(
                                    color: AppColors.onSurfaceVariant, fontSize: 13),
                              ),
                      ),
              ),
              const SizedBox(width: 8),
              Artwork(
                localPath: widget.song.thumbnailPath,
                url: widget.song.thumbnailUrl,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? AppColors.primary : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.song.author.isNotEmpty)
                      Text(
                        widget.song.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                  ],
                ),
              ),
              IconButton(
                iconSize: 18,
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                color: isFav ? AppColors.primary : AppColors.onSurfaceVariant,
                onPressed: () => app.toggleFavorite(widget.song.id),
              ),
              const SizedBox(width: 4),
              if (widget.song.durationSeconds > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    formatDuration(widget.song.durationSeconds),
                    style: const TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              PopupMenuButton<String>(
                color: AppColors.surfaceElevated,
                iconSize: 18,
                icon: const Icon(Icons.more_horiz, color: AppColors.onSurfaceVariant),
                tooltip: l10n.moreOptions,
                onSelected: (v) {
                  switch (v) {
                    case 'next':
                      player.playNext(widget.song);
                    case 'queue':
                      player.addToQueue(widget.song);
                    case 'playlist':
                      showAddToPlaylistSheet(context, widget.song);
                    case 'delete':
                      widget.onDelete?.call();
                    case 'removePlaylist':
                      widget.onRemoveFromPlaylist?.call();
                    case 'more':
                      widget.onMenu?.call();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'next',
                      child: ListTile(
                          leading: const Icon(Icons.queue_play_next),
                          title: Text(l10n.playNext))),
                  PopupMenuItem(
                      value: 'queue',
                      child: ListTile(
                          leading: const Icon(Icons.add_to_queue),
                          title: Text(l10n.addToQueue))),
                  PopupMenuItem(
                      value: 'playlist',
                      child: ListTile(
                          leading: const Icon(Icons.playlist_add),
                          title: Text(l10n.addToPlaylist))),
                  if (widget.onRemoveFromPlaylist != null) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                        value: 'removePlaylist',
                        child: ListTile(
                            leading: const Icon(Icons.playlist_remove,
                                color: Colors.redAccent),
                            title: Text(l10n.removeFromPlaylist,
                                style: const TextStyle(color: Colors.redAccent)))),
                  ],
                  if (widget.onDelete != null) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            title: Text(l10n.delete,
                                style: const TextStyle(color: Colors.redAccent)))),
                  ],
                  if (widget.onMenu != null) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                        value: 'more',
                        child: ListTile(
                            leading: const Icon(Icons.more_horiz),
                            title: Text(l10n.moreOptions))),
                  ],
                ],
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
