import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/song.dart';
import '../../services/download_manager.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

/// Botón de descarga para una canción. Refleja el estado (no descargada,
/// descargando, descargada). `labeled` usa un botón con texto (pantalla de la
/// canción); por defecto es compacto solo-ícono (reproductor inferior).
class SongDownloadButton extends StatelessWidget {
  const SongDownloadButton({super.key, required this.song, this.labeled = false});

  final Song song;
  final bool labeled;

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadManager>();
    final app = context.watch<AppState>();
    final l10n = AppLocalizations.of(context);
    final task = downloads.taskFor(song.id);

    final downloaded = song.filePath.isNotEmpty ||
        app.songsById.containsKey(song.id) ||
        task?.status == DownloadStatus.done;
    final inProgress = task?.status == DownloadStatus.downloading ||
        task?.status == DownloadStatus.queued;
    final progress =
        task?.status == DownloadStatus.downloading && (task?.progress ?? 0) > 0
            ? task!.progress
            : null;

    if (labeled) {
      if (downloaded) {
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, color: AppColors.primary),
          label: Text(l10n.downloaded),
        );
      }
      if (inProgress) {
        return OutlinedButton.icon(
          onPressed: null,
          icon: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, value: progress, color: AppColors.primary),
          ),
          label: Text(l10n.downloading),
        );
      }
      return OutlinedButton.icon(
        onPressed: () => _enqueue(downloads),
        icon: const Icon(Icons.download_rounded),
        label: Text(l10n.download),
      );
    }

    // compacto (solo ícono)
    if (downloaded) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.check_circle, color: AppColors.primary, size: 18),
      );
    }
    if (inProgress) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, value: progress, color: AppColors.primary),
          ),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.download_rounded, size: 18),
      color: AppColors.onSurfaceVariant,
      tooltip: l10n.download,
      onPressed: () => _enqueue(downloads),
    );
  }

  void _enqueue(DownloadManager downloads) {
    downloads.enqueue(song.id, song.title, song.author,
        thumbnailUrl: song.thumbnailUrl ?? '');
  }
}
