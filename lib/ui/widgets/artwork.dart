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

/// Carátula de una playlist: imagen de la primera canción ([localPath]/[url]);
/// si no hay, un degradado con [fallbackIcon]. Puede ser rectangular (tarjetas)
/// o cuadrada (cabecera).
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({
    super.key,
    this.localPath,
    this.url,
    required this.fallbackIcon,
    this.width = double.infinity,
    this.height = 140,
    this.radius = 6,
    this.iconSize = 52,
  });

  final String? localPath;
  final String? url;
  final IconData fallbackIcon;
  final double width;
  final double height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (localPath != null && localPath!.isNotEmpty && File(localPath!).existsSync()) {
      child = Image.file(File(localPath!), width: width, height: height, fit: BoxFit.cover);
    } else if (url != null && url!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _gradient(),
        errorWidget: (_, __, ___) => _gradient(),
      );
    } else {
      child = _gradient();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  Widget _gradient() => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withValues(alpha: 0.7), AppColors.surfaceElevated],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(fallbackIcon, size: iconSize, color: Colors.white),
      );
}

String formatDuration(int seconds) {
  if (seconds <= 0) return '';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatDurationD(Duration d) => formatDuration(d.inSeconds);
