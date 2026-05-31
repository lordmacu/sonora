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

/// Carátula de una playlist en mosaico, estilo Spotify, según cuántas imágenes
/// haya: 1 = completa, 2 = mitades, 3 = una arriba y dos abajo, 4+ = 2×2.
/// Si no hay imágenes, un degradado con [fallbackIcon].
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({
    super.key,
    required this.images,
    required this.fallbackIcon,
    this.width = double.infinity,
    this.height = 140,
    this.radius = 6,
    this.iconSize = 52,
  });

  final List<({String? localPath, String? url})> images;
  final IconData fallbackIcon;
  final double width;
  final double height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: _mosaic()),
    );
  }

  Widget _mosaic() {
    final imgs = images.take(4).toList();
    switch (imgs.length) {
      case 0:
        return _gradient();
      case 1:
        return _tile(imgs[0]);
      case 2:
        // mitades izquierda / derecha
        return Row(children: [
          Expanded(child: _tile(imgs[0])),
          Expanded(child: _tile(imgs[1])),
        ]);
      case 3:
        // una arriba (ancho completo), dos abajo
        return Column(children: [
          Expanded(child: _tile(imgs[0])),
          Expanded(
            child: Row(children: [
              Expanded(child: _tile(imgs[1])),
              Expanded(child: _tile(imgs[2])),
            ]),
          ),
        ]);
      default:
        // 2×2
        return Column(children: [
          Expanded(
            child: Row(children: [
              Expanded(child: _tile(imgs[0])),
              Expanded(child: _tile(imgs[1])),
            ]),
          ),
          Expanded(
            child: Row(children: [
              Expanded(child: _tile(imgs[2])),
              Expanded(child: _tile(imgs[3])),
            ]),
          ),
        ]);
    }
  }

  /// Una celda del mosaico que llena su espacio asignado.
  Widget _tile(({String? localPath, String? url}) img) {
    final localPath = img.localPath;
    final url = img.url;
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      return Image.file(File(localPath),
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => _gradient(),
        errorWidget: (_, __, ___) => _gradient(),
      );
    }
    return _gradient();
  }

  Widget _gradient() => Container(
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
