import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../models/youtube_result.dart';
import '../../services/download_manager.dart';
import '../../services/player_service.dart';
import '../../services/youtube_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/artwork.dart';
import '../widgets/song_row.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  List<YoutubeResult> _results = [];
  String _searchedQuery = ''; // consulta cuyos _results remotos están vigentes
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // restaurar la última búsqueda para que no se pierda al volver a la vista
    final app = context.read<AppState>();
    _controller.text = app.searchQuery;
    _results = app.searchResults;
    _searchedQuery = app.searchQuery;
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final yt = context.read<YoutubeService>();
      final res = await yt.search(q);
      if (!mounted) return;
      context.read<AppState>().setSearch(q, res);
      setState(() {
        _results = res;
        _searchedQuery = q;
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setState(() {}), // filtra descargas en vivo
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _search, child: Text(l10n.searchButton)),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Text(l10n.errorWithMessage(_error!),
            style: const TextStyle(color: AppColors.onSurfaceVariant)),
      );
    }

    final q = _controller.text.trim();

    // Resultados remotos vigentes (ya se pulsó "Buscar" para esta consulta).
    if (q.isNotEmpty && q == _searchedQuery && _results.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _results.length,
        itemBuilder: (_, i) => _ResultRow(result: _results[i]),
      );
    }

    // Mientras se escribe: filtrar las descargas locales.
    if (q.isNotEmpty) {
      final app = context.watch<AppState>();
      final player = context.read<PlayerService>();
      final ql = q.toLowerCase();
      final local = app.downloadedSongs
          .where((s) =>
              s.title.toLowerCase().contains(ql) ||
              s.author.toLowerCase().contains(ql))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
            child: Text(
              local.isEmpty ? l10n.noLocalMatches : l10n.inDownloadsHint,
              style: const TextStyle(
                  color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Expanded(
            child: local.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: local.length,
                    itemBuilder: (_, i) => SongRow(
                      song: local[i],
                      index: i,
                      onPlay: () => player.playSongs(local, startIndex: i),
                    ),
                  ),
          ),
        ],
      );
    }

    return Center(
      child: Text(l10n.searchInitialHint,
          style: const TextStyle(color: AppColors.onSurfaceVariant)),
    );
  }
}

class _ResultRow extends StatefulWidget {
  const _ResultRow({required this.result});
  final YoutubeResult result;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  bool _hover = false;

  Song _asSong() => Song(
        id: widget.result.videoId,
        title: widget.result.title,
        author: widget.result.author,
        filePath: '',
        thumbnailUrl: widget.result.thumbnailUrl,
        durationSeconds: widget.result.durationSeconds,
        isYoutube: true,
      );

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadManager>();
    final player = context.watch<PlayerService>();
    final app = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);
    final r = widget.result;

    final task = downloads.taskFor(r.videoId);
    final isDownloaded = app.songsById.containsKey(r.videoId);
    final isCurrent = player.current?.id == r.videoId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _hover ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Artwork(url: r.thumbnailUrl, size: 44),
                if (_hover || isCurrent)
                  GestureDetector(
                    onTap: () => player.playSingle(_asSong()),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: Colors.black54,
                      child: Icon(
                          isCurrent && player.playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isCurrent ? AppColors.primary : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  if (r.author.isNotEmpty)
                    Text(r.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            if (r.durationSeconds > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(formatDuration(r.durationSeconds),
                    style: const TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 12)),
              ),
            PopupMenuButton<String>(
              color: AppColors.surfaceElevated,
              icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant, size: 20),
              tooltip: l10n.moreOptions,
              onSelected: (v) {
                final song = _asSong();
                switch (v) {
                  case 'next':
                    player.playNext(song);
                  case 'queue':
                    player.addToQueue(song);
                  case 'playlist':
                    showAddToPlaylistSheet(context, song);
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
              ],
            ),
            _downloadButton(context, downloads, task, isDownloaded),
          ],
        ),
      ),
    );
  }

  Widget _downloadButton(BuildContext context, DownloadManager downloads,
      DownloadTask? task, bool isDownloaded) {
    if (isDownloaded || task?.status == DownloadStatus.done) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
      );
    }
    if (task?.status == DownloadStatus.downloading ||
        task?.status == DownloadStatus.queued) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
              value: task!.status == DownloadStatus.downloading && task.progress > 0
                  ? task.progress
                  : null,
            ),
          ),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.download_rounded),
      color: AppColors.onSurfaceVariant,
      iconSize: 20,
      tooltip: AppLocalizations.of(context).download,
      onPressed: () {
        final r = widget.result;
        downloads.enqueue(r.videoId, r.title, r.author, thumbnailUrl: r.thumbnailUrl);
      },
    );
  }
}
