import 'package:flutter/material.dart';

/// Neon-Noir Underground palette.
/// Pitch-black canvas, surgical crimson signature, bone-warm text.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF0A0A0E);
  static const Color obsidian = Color(0xFF13141A);
  static const Color graphite = Color(0xFF1C1E28);
  static const Color slate = Color(0xFF262835);

  static const Color bone = Color(0xFFF5F1E8);
  static const Color ash = Color(0xFF8B8D9B);
  static const Color smoke = Color(0xFF5A5C6A);

  static const Color crimson = Color(0xFFFF2E4D);
  static const Color crimsonDeep = Color(0xFFD1233B);
  static const Color emberGlow = Color(0xFFFF6B7E);

  static const Color hairline = Color(0xFF26283A);

  // Legacy aliases kept so older imports still compile.
  static const Color primary = crimson;
  static const Color background = ink;
  static const Color surface = obsidian;
  static const Color softSurface = graphite;
  static const Color textPrimary = bone;
  static const Color textSecondary = ash;
  static const Color border = hairline;
}
