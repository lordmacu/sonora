import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/import_track.dart';
import '../../services/csv_import.dart';
import '../../services/download_manager.dart';
import '../../services/spotify_import.dart';
import '../../services/youtube_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final _csv = CsvImportService();
  final _spotify = SpotifyImportService();
  List<ImportTrack> _tracks = [];
  String? _sourceName; // nombre de la playlist/álbum importado (Spotify/CSV)
  String? _importPlaylistId; // playlist creada para esta importación
  bool _loading = false;
  bool _downloading = false;
  String? _error;

  @override
  void dispose() {
    _spotify.dispose();
    super.dispose();
  }

  Future<void> _importSpotify() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Importar de Spotify',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Pega el enlace de una playlist, álbum o canción de Spotify (incluidas las editoriales). No requiere login.',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'https://open.spotify.com/playlist/... (o /album/, /track/)'),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Importar')),
        ],
      ),
    );
    if (url == null || url.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pl = await _spotify.fetchFromUrl(url.trim());
      if (!mounted) return;
      setState(() {
        _tracks = pl.tracks;
        _sourceName = pl.name;
        _importPlaylistId = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickCsv() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final file = res?.files.single;
    final path = file?.path;
    if (path == null) return;
    // nombre de la lista = nombre del archivo sin extensión
    final fileName = file!.name.replaceAll(RegExp(r'\.csv$', caseSensitive: false), '');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tracks = await _csv.parseFile(path);
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _sourceName = fileName;
        _importPlaylistId = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int get _selectedCount => _tracks.where((t) => t.selected).length;

  /// Procesa las pistas seleccionadas: busca cada una en YouTube, la agrega a la
  /// playlist (con metadatos) y, si [download] es true, además la encola para
  /// descargar. Si es false, queda en la playlist como streaming (sin bajar).
  Future<void> _process({required bool download}) async {
    final yt = context.read<YoutubeService>();
    final downloads = context.read<DownloadManager>();
    final app = context.read<AppState>();
    setState(() => _downloading = true);

    // Crear la playlist destino una sola vez, con el nombre importado.
    if (_importPlaylistId == null) {
      final pl = await app.createPlaylist(_sourceName?.trim().isNotEmpty == true
          ? _sourceName!.trim()
          : 'Importada');
      _importPlaylistId = pl.id;
    }
    final playlistId = _importPlaylistId!;

    final pending = _tracks
        .where((t) => t.selected && t.state == TrackDownloadState.pending)
        .toList();

    for (final track in pending) {
      if (!mounted) return;
      setState(() => track.state = TrackDownloadState.searching);
      try {
        final results = await yt.search(track.searchQuery);
        if (results.isEmpty) {
          if (mounted) setState(() => track.state = TrackDownloadState.error);
          continue;
        }
        final r = results.first;
        track.videoId = r.videoId;
        // Siempre: guardar metadatos + agregar a la playlist (reproducible aunque
        // no se descargue; al descargarse pasa a local).
        await app.playlistService.saveSongMeta(
          r.videoId,
          track.name,
          track.artists,
          r.thumbnailUrl,
          (track.durationMs / 1000).round(),
        );
        await app.playlistService.addSong(playlistId, r.videoId);

        if (download) {
          downloads.enqueue(r.videoId, track.name, track.artists,
              thumbnailUrl: r.thumbnailUrl);
          if (mounted) setState(() => track.state = TrackDownloadState.downloading);
        } else {
          // Solo agregada (streaming): la marcamos como lista.
          if (mounted) setState(() => track.state = TrackDownloadState.done);
        }
      } catch (_) {
        if (mounted) setState(() => track.state = TrackDownloadState.error);
      }
    }
    await app.refreshPlaylists();
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadManager>();

    // sincronizar estado de descarga real
    for (final t in _tracks) {
      final vid = t.videoId;
      if (vid == null) continue;
      final task = downloads.taskFor(vid);
      if (task == null) continue;
      if (task.status == DownloadStatus.done) {
        t.state = TrackDownloadState.done;
      } else if (task.status == DownloadStatus.error) {
        t.state = TrackDownloadState.error;
      } else if (task.status == DownloadStatus.downloading) {
        t.state = TrackDownloadState.downloading;
        t.progress = task.progress;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Importar playlists',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                        'Pega el enlace de una playlist pública de Spotify, o importa un CSV (Exportify / TuneMyMusic). Las canciones se buscan y descargan desde YouTube.',
                        style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: _loading ? null : _importSpotify,
                    icon: const Icon(Icons.library_music),
                    label: const Text('Spotify'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _pickCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('CSV'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Text('Error: $_error',
                style: const TextStyle(color: Colors.redAccent)),
          ),
        if (_tracks.isNotEmpty) _toolbar(),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _toolbar() {
    final allSelected = _selectedCount == _tracks.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              for (final t in _tracks) {
                t.selected = !allSelected;
              }
            }),
            icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
            label: Text(allSelected ? 'Deseleccionar' : 'Seleccionar todo'),
          ),
          const Spacer(),
          if (_sourceName != null) ...[
            Flexible(
              child: Text(_sourceName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            const Text('·', style: TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(width: 8),
          ],
          Text('${_tracks.length} canciones',
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: (_downloading || _selectedCount == 0)
                ? null
                : () => _process(download: false),
            icon: const Icon(Icons.playlist_add),
            label: Text('Agregar a lista ($_selectedCount)'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: (_downloading || _selectedCount == 0)
                ? null
                : () => _process(download: true),
            icon: _downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.download),
            label: Text('Descargar ($_selectedCount)'),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_tracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add, size: 56, color: AppColors.onSurfaceVariant),
            SizedBox(height: 12),
            Text('Importa desde Spotify o un CSV para empezar',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _tracks.length,
      itemBuilder: (_, i) => _TrackRow(
        track: _tracks[i],
        onToggle: () => setState(() => _tracks[i].selected = !_tracks[i].selected),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track, required this.onToggle});
  final ImportTrack track;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Checkbox(
            value: track.selected,
            onChanged: track.state == TrackDownloadState.pending
                ? (_) => onToggle()
                : null,
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(track.artists,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _stateWidget(),
        ],
      ),
    );
  }

  Widget _stateWidget() {
    switch (track.state) {
      case TrackDownloadState.pending:
        return const SizedBox(width: 80);
      case TrackDownloadState.searching:
        return const SizedBox(
          width: 80,
          child: Text('Buscando…',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
        );
      case TrackDownloadState.downloading:
        return SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                    value: track.progress > 0 ? track.progress : null),
              ),
            ],
          ),
        );
      case TrackDownloadState.done:
        return const SizedBox(
          width: 80,
          child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        );
      case TrackDownloadState.error:
        return const SizedBox(
          width: 80,
          child: Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
        );
    }
  }
}
