import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/playlist.dart';
import '../../services/player_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../widgets/artwork.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return l10n.greetingMorning;
    if (h >= 12 && h < 21) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final player = context.read<PlayerService>();
    final l10n = AppLocalizations.of(context);
    final recent = app.downloadedSongs.take(6).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      children: [
        Text(_greeting(l10n),
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        // accesos rápidos
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _QuickCard(
              icon: Icons.search,
              label: l10n.quickSearch,
              onTap: () => app.go(AppView.search),
            ),
            _QuickCard(
              icon: Icons.download,
              label: l10n.quickDownloads,
              onTap: () => app.go(AppView.downloads),
            ),
            _QuickCard(
              icon: Icons.playlist_add,
              label: l10n.quickImport,
              onTap: () => app.go(AppView.import),
            ),
            _QuickCard(
              icon: Icons.favorite,
              label: l10n.favorites,
              onTap: () => app.openPlaylist(Playlist.favoritesId),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (recent.isNotEmpty) ...[
          Text(l10n.recentlyPlayed,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                final s = recent[i];
                return _AlbumCard(
                  title: s.title,
                  subtitle: s.author,
                  localPath: s.thumbnailPath,
                  url: s.thumbnailUrl,
                  onPlay: () => player.playSongs(app.downloadedSongs, startIndex: i),
                );
              },
            ),
          ),
        ] else
          _EmptyHome(onSearch: () => app.go(AppView.search)),
        const SizedBox(height: 32),
        if (app.playlists.isNotEmpty) ...[
          Text(l10n.yourPlaylists,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final pl in app.playlists)
                SizedBox(
                  width: 160,
                  child: _AlbumCard(
                    title: pl.name,
                    subtitle: l10n.songsCount(app.playlistService.songCount(pl.id)),
                    icon: pl.id == Playlist.favoritesId
                        ? Icons.favorite
                        : Icons.queue_music,
                    onPlay: () => app.openPlaylist(pl.id),
                    onTap: () => app.openPlaylist(pl.id),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  const _AlbumCard({
    required this.title,
    required this.subtitle,
    this.localPath,
    this.url,
    this.icon,
    required this.onPlay,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? localPath;
  final String? url;
  final IconData? icon;
  final VoidCallback onPlay;
  final VoidCallback? onTap;

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap ?? widget.onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hover ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  widget.icon != null
                      ? Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(widget.icon, color: AppColors.primary, size: 48),
                        )
                      : Artwork(
                          localPath: widget.localPath,
                          url: widget.url,
                          size: 136,
                          radius: 6,
                        ),
                  if (_hover)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: widget.onPlay,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(widget.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Icon(Icons.music_note, size: 56, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).emptyHomeTitle,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).emptyHomeSubtitle,
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: Text(AppLocalizations.of(context).quickSearch),
          ),
        ],
      ),
    );
  }
}
