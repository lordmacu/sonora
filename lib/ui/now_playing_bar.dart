import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/player_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'widgets/add_to_playlist.dart';
import 'widgets/artwork.dart';
import 'widgets/download_button.dart';

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    // watch (no read) para que el corazón se actualice al instante al dar
    // like/dislike: toggleFavorite -> refreshPlaylists -> notifyListeners.
    final app = context.watch<AppState>();
    final song = player.current;

    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // info de la canción
          Expanded(
            flex: 3,
            child: song == null
                ? const SizedBox()
                : InkWell(
                    onTap: () => app.setPlayerExpanded(true),
                    child: Row(
                      children: [
                        Artwork(
                          localPath: song.thumbnailPath,
                          url: song.thumbnailUrl,
                          size: 56,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(song.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(app.isFavorite(song.id)
                              ? Icons.favorite
                              : Icons.favorite_border),
                          color: app.isFavorite(song.id)
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          iconSize: 18,
                          onPressed: () => app.toggleFavorite(song.id),
                        ),
                      ],
                    ),
                  ),
          ),
          // controles + barra de progreso
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle,
                          color: player.shuffle ? AppColors.primary : AppColors.onSurfaceVariant),
                      iconSize: 18,
                      onPressed: player.toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      iconSize: 24,
                      onPressed: player.previous,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: IconButton(
                        icon: player.buffering
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : Icon(player.playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.black),
                        iconSize: 24,
                        onPressed: player.hasSong ? player.togglePlay : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      iconSize: 24,
                      onPressed: () => player.next(),
                    ),
                    IconButton(
                      icon: Icon(
                        player.repeat == RepeatMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: player.repeat == RepeatMode.none
                            ? AppColors.onSurfaceVariant
                            : AppColors.primary,
                      ),
                      iconSize: 18,
                      onPressed: player.cycleRepeat,
                    ),
                  ],
                ),
                _ProgressBar(player: player),
              ],
            ),
          ),
          // espacio derecho (volumen / expandir)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (song != null) SongDownloadButton(song: song),
                IconButton(
                  icon: const Icon(Icons.playlist_add, size: 20),
                  color: AppColors.onSurfaceVariant,
                  tooltip: AppLocalizations.of(context).addToPlaylist,
                  onPressed:
                      song == null ? null : () => showAddToPlaylistSheet(context, song),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_full, size: 18),
                  color: AppColors.onSurfaceVariant,
                  onPressed: song == null ? null : () => app.setPlayerExpanded(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.player});
  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    final pos = player.position;
    final dur = player.duration;
    final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final value = pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
    return Row(
      children: [
        Text(formatDurationD(pos),
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              min: 0,
              max: maxMs,
              value: value,
              onChanged: (v) =>
                  player.seek(Duration(milliseconds: v.toInt())),
            ),
          ),
        ),
        Text(formatDurationD(dur),
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
      ],
    );
  }
}
