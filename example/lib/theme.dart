import 'package:flutter/material.dart';

/// The native app's palette, from `Face-LivenessDetection-Android/app/src/main/res/values/colors.xml`.
/// Kept as exact hex so the Flutter demo matches the Android and iOS screens.
abstract final class FP {
  static const Color bg = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF14141D);
  static const Color surfaceAlt = Color(0xFF1B1B27);
  static const Color text = Color(0xFFF2F0F7);
  static const Color muted = Color(0xFF9B96AC);
  static const Color accent = Color(0xFFA48CFF);
  static const Color accentDim = Color(0xFF2A2140);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color stroke = Color(0xFF262635);

  static const Color brandViolet = Color(0xFF7C5CFF);
  static const Color brandVioletDeep = Color(0xFF4A2BB5);

  static const Color statusError = Color(0xFFE5484D);
  static const Color statusOk = Color(0xFF2EE6A6);
  static const Color statusInfo = Color(0xFF5B8DEF);

  /// `bg_hero.xml` — a 135° linear gradient with a 28dp radius and a 1dp stroke.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF241B46), Color(0xFF101019)],
  );

  /// `bg_tile_primary.xml` — the Active-liveness card.
  static const LinearGradient primaryTileGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[brandViolet, brandVioletDeep],
  );

  static ThemeData theme() {
    final ColorScheme scheme = const ColorScheme.dark().copyWith(
      surface: bg,
      primary: accent,
      secondary: brandViolet,
      error: statusError,
      onSurface: text,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      splashColor: Colors.white24,
    );
  }
}

/// `bg_card.xml` / `bg_tile_surface.xml` — a surface card with a hairline stroke.
BoxDecoration fpCard({double radius = 20}) => BoxDecoration(
      color: FP.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: FP.stroke),
    );
