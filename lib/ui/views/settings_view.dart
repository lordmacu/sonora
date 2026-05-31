import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/player_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _scanning = false;
  int? _scannedCount;

  Future<void> _pickFolder() async {
    final app = context.read<AppState>();
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    await app.library.setLocalFolder(dir);
    setState(() => _scanning = true);
    final songs = await app.library.scanLocalFolder(dir);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _scannedCount = songs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final player = context.read<PlayerService>();
    final l10n = AppLocalizations.of(context);
    final localFolder = app.library.localFolder;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      children: [
        Text(l10n.settings,
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _section(l10n.localLibrary),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.localMusicFolder,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(localFolder ?? l10n.notSelected,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
              if (_scannedCount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.audioFilesFound(_scannedCount!),
                      style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _scanning ? null : _pickFolder,
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.chooseFolder),
                  ),
                  const SizedBox(width: 12),
                  if (localFolder != null)
                    FilledButton.icon(
                      onPressed: _scanning
                          ? null
                          : () async {
                              final songs =
                                  await app.library.scanLocalFolder(localFolder);
                              if (songs.isNotEmpty) {
                                await player.playSongs(songs);
                              }
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.playFolder),
                    ),
                  if (_scanning) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _section(l10n.storage),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.downloadedSongsCount(app.downloadedSongs.length),
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                l10n.mbOnDisk((app.downloadedSongs.fold<int>(0, (s, e) => s + e.fileSizeBytes) / (1024 * 1024)).toStringAsFixed(1)),
                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _section(l10n.about),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sonora',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(l10n.appTagline,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );
}
