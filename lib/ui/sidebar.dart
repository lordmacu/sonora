import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/playlist.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'widgets/artwork.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);

    return Container(
      width: 240,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.graphic_eq, color: Colors.black, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Sonora',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _NavItem(
            icon: Icons.home_rounded,
            label: l10n.navHome,
            selected: app.view == AppView.home,
            onTap: () => app.go(AppView.home),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: l10n.navSearch,
            selected: app.view == AppView.search,
            onTap: () => app.go(AppView.search),
          ),
          _NavItem(
            icon: Icons.download_rounded,
            label: l10n.navDownloads,
            selected: app.view == AppView.downloads,
            onTap: () => app.go(AppView.downloads),
          ),
          _NavItem(
            icon: Icons.library_music_rounded,
            label: l10n.navPlaylists,
            selected: app.view == AppView.playlists,
            onTap: () => app.go(AppView.playlists),
          ),
          _NavItem(
            icon: Icons.playlist_add_rounded,
            label: l10n.navImport,
            selected: app.view == AppView.import,
            onTap: () => app.go(AppView.import),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 24, endIndent: 24),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.playlistsHeader,
                    style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add, color: AppColors.onSurfaceVariant),
                  onPressed: () => _createPlaylist(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final pl in app.playlists)
                  _PlaylistItem(
                    playlist: pl,
                    selected: app.view == AppView.playlistDetail &&
                        app.currentPlaylistId == pl.id,
                    onTap: () => app.openPlaylist(pl.id),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _NavItem(
            icon: Icons.settings_rounded,
            label: l10n.navSettings,
            selected: app.view == AppView.settings,
            onTap: () => app.go(AppView.settings),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final app = context.read<AppState>();
    final name = await _promptName(context, AppLocalizations.of(context).newPlaylist);
    if (name == null || name.trim().isEmpty) return;
    final pl = await app.playlistService.create(name.trim());
    await app.refreshPlaylists();
    app.openPlaylist(pl.id);
  }
}

Future<String?> _promptName(BuildContext context, String title,
    {String initial = ''}) {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text(title, style: const TextStyle(color: Colors.white)),
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
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.onSurfaceVariant, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistItem extends StatelessWidget {
  const _PlaylistItem({
    required this.playlist,
    required this.selected,
    required this.onTap,
  });

  final Playlist playlist;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Conteo de canciones mostrables (no ids huérfanos). El sidebar observa
    // AppState arriba, así que se actualiza al quitar/agregar/borrar.
    final app = context.read<AppState>();
    final count = app.resolvedCountOf(playlist.id);
    final cover = app.singleCoverOf(playlist.id);
    final icon = playlist.id == Playlist.favoritesId
        ? Icons.favorite
        : playlist.id == Playlist.generalId
            ? Icons.queue_music
            : Icons.playlist_play;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        color: selected ? Colors.white.withValues(alpha: 0.07) : null,
        child: Row(
          children: [
            if (cover != null)
              Artwork(localPath: cover.localPath, url: cover.url, size: 32, radius: 4)
            else
              SizedBox(
                width: 32,
                height: 32,
                child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(AppLocalizations.of(context).songsCount(count),
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
