import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../services/player_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../widgets/artwork.dart';
import '../widgets/song_row.dart';

class DownloadsView extends StatefulWidget {
  const DownloadsView({super.key});

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

enum _Sort { title, date }

class _DownloadsViewState extends State<DownloadsView> {
  _Sort _sort = _Sort.title;
  bool _selecting = false;
  final Set<String> _selected = {};

  List<Song> _sorted(List<Song> songs) {
    final list = [...songs];
    if (_sort == _Sort.title) {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      list.sort((a, b) => b.lastModifiedMs.compareTo(a.lastModifiedMs));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final player = context.read<PlayerService>();
    final songs = _sorted(app.downloadedSongs);
    final totalMb = app.downloadedSongs.fold<int>(0, (s, e) => s + e.fileSizeBytes) /
        (1024 * 1024);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // cabecera tipo Spotify
        Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryVariant],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Descargas',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${app.downloadedSongs.length} canciones · ${totalMb.toStringAsFixed(1)} MB',
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        // controles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _selecting
              ? _selectionBar(songs)
              : _normalControls(songs, player),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: songs.isEmpty
              ? const Center(
                  child: Text('No tienes descargas todavía',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: songs.length,
                  itemBuilder: (_, i) {
                    final song = songs[i];
                    if (_selecting) return _selectableRow(song);
                    return SongRow(
                      song: song,
                      index: i,
                      onPlay: () => player.playSongs(songs, startIndex: i),
                      onDelete: () => _deleteSong(song),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _normalControls(List<Song> songs, PlayerService player) {
    return Row(
      children: [
        if (songs.isNotEmpty)
          FilledButton.icon(
            onPressed: () => player.playSongs(songs),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Reproducir'),
          ),
        const SizedBox(width: 12),
        if (songs.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () {
              player.toggleShuffle();
              player.playSongs(songs);
            },
            icon: const Icon(Icons.shuffle),
            label: const Text('Aleatorio'),
          ),
        const Spacer(),
        if (songs.isNotEmpty)
          TextButton.icon(
            onPressed: () => setState(() {
              _selecting = true;
              _selected.clear();
            }),
            icon: const Icon(Icons.checklist),
            label: const Text('Seleccionar'),
          ),
        const SizedBox(width: 8),
        const Text('Ordenar:',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
        const SizedBox(width: 8),
        DropdownButton<_Sort>(
          value: _sort,
          dropdownColor: AppColors.surfaceElevated,
          underline: const SizedBox(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: const [
            DropdownMenuItem(value: _Sort.title, child: Text('Título')),
            DropdownMenuItem(value: _Sort.date, child: Text('Fecha')),
          ],
          onChanged: (v) => setState(() => _sort = v ?? _Sort.title),
        ),
      ],
    );
  }

  Widget _selectionBar(List<Song> songs) {
    final allSelected =
        songs.isNotEmpty && _selected.length == songs.length;
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => setState(() {
            if (allSelected) {
              _selected.clear();
            } else {
              _selected
                ..clear()
                ..addAll(songs.map((s) => s.id));
            }
          }),
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          label: Text(allSelected ? 'Ninguno' : 'Seleccionar todos'),
        ),
        const Spacer(),
        Text('${_selected.length} seleccionadas',
            style: const TextStyle(color: AppColors.onSurfaceVariant)),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _selected.isEmpty ? null : () => _deleteSelected(songs),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          icon: const Icon(Icons.delete_outline),
          label: Text('Eliminar (${_selected.length})'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => setState(() {
            _selecting = false;
            _selected.clear();
          }),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _selectableRow(Song song) {
    final selected = _selected.contains(song.id);
    return InkWell(
      onTap: () => setState(() {
        if (selected) {
          _selected.remove(song.id);
        } else {
          _selected.add(song.id);
        }
      }),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => setState(() {
                if (selected) {
                  _selected.remove(song.id);
                } else {
                  _selected.add(song.id);
                }
              }),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Artwork(
              localPath: song.thumbnailPath,
              url: song.thumbnailUrl,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  if (song.author.isNotEmpty)
                    Text(song.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelected(List<Song> songs) async {
    final app = context.read<AppState>();
    final ids = _selected.toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Eliminar descargas',
            style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar ${ids.length} canción(es) descargada(s)?',
            style: const TextStyle(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final id in ids) {
      await app.library.deleteDownload(id);
    }
    await app.refreshLibrary();
    if (mounted) {
      setState(() {
        _selecting = false;
        _selected.clear();
      });
    }
  }

  Future<void> _deleteSong(Song song) async {
    final app = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Eliminar descarga',
            style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${song.title}"?',
            style: const TextStyle(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await app.library.deleteDownload(song.id);
    await app.refreshLibrary();
  }
}
