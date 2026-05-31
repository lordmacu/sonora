import 'package:flutter/material.dart';

/// Paleta tipo Spotify (verde #1DB954, fondos oscuros).
class AppColors {
  static const primary = Color(0xFF1DB954);
  static const primaryVariant = Color(0xFF169040);
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF242424);
  static const sidebar = Color(0xFF000000);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFB3B3B3);
  static const onPrimary = Color(0xFF000000);
  static const divider = Color(0xFF2A2A2A);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
      onPrimary: AppColors.onPrimary,
      onSurface: AppColors.onSurface,
    ),
    canvasColor: AppColors.surface,
    dividerColor: AppColors.divider,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
      fontFamily: 'SF Pro Display',
    ),
    iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      textStyle: TextStyle(color: Colors.white, fontSize: 12),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.divider,
      thumbColor: Colors.white,
      trackHeight: 4,
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
