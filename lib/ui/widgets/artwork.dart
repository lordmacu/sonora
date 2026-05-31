import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

/// Carátula de canción: archivo local → URL remota → ícono de música.
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    this.localPath,
    this.url,
    this.size = 48,
    this.radius = 6,
  });

  final String? localPath;
  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (localPath != null && localPath!.isNotEmpty && File(localPath!).existsSync()) {
      child = Image.file(File(localPath!), width: size, height: size, fit: BoxFit.cover);
    } else if (url != null && url!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    } else {
      child = _fallback();
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        color: AppColors.surfaceElevated,
        child: Icon(Icons.music_note, color: AppColors.onSurfaceVariant, size: size * 0.5),
      );
}

String formatDuration(int seconds) {
  if (seconds <= 0) return '';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatDurationD(Duration d) => formatDuration(d.inSeconds);
