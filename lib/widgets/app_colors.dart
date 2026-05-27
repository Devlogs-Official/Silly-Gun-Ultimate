import 'package:flutter/material.dart';

/// Brand-constant colors that read the same in both light and dark themes.
/// For theme-adapting surface / text / border colors, use
/// `context.palette` (see `app_palette.dart`).
class AppColors {
  AppColors._();

  static const Color crimson = Color(0xFFFF2E4D);
  static const Color crimsonDeep = Color(0xFFD1233B);
  static const Color emberGlow = Color(0xFFFF6B7E);

  /// Fallback values — only used in `const` contexts and dark-themed scopes.
  /// Most widgets should prefer `context.palette` instead.
  static const Color ink = Color(0xFF0A0A0E);
  static const Color obsidian = Color(0xFF13141A);
  static const Color graphite = Color(0xFF1C1E28);
  static const Color bone = Color(0xFFF5F1E8);
  static const Color ash = Color(0xFF8B8D9B);
  static const Color smoke = Color(0xFF5A5C6A);
  static const Color hairline = Color(0xFF26283A);
  static const Color slate = Color(0xFF262835);

  // Legacy aliases.
  static const Color primary = crimson;
  static const Color background = ink;
  static const Color surface = obsidian;
  static const Color softSurface = graphite;
  static const Color textPrimary = bone;
  static const Color textSecondary = ash;
  static const Color border = hairline;
}
