import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Neon-Noir typography stack.
/// Display: Bebas Neue — condensed, brutalist, uppercase.
/// Body: Manrope — geometric humanist, soft but precise.
class AppText {
  AppText._();

  static TextStyle display({
    double size = 44,
    Color color = AppColors.bone,
    double letterSpacing = 2.0,
    FontWeight weight = FontWeight.w400,
    double height = 0.95,
  }) {
    return GoogleFonts.bebasNeue(
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      height: height,
    );
  }

  static TextStyle eyebrow({
    Color color = AppColors.crimson,
    double size = 11,
    double letterSpacing = 3.6,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w800,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle headline({
    double size = 22,
    Color color = AppColors.bone,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: 1.18,
    );
  }

  static TextStyle body({
    double size = 14.5,
    Color color = AppColors.ash,
    FontWeight weight = FontWeight.w500,
    double height = 1.55,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: 0.1,
    );
  }

  static TextStyle button({
    Color color = AppColors.bone,
    double size = 13,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
    );
  }

  static TextStyle mono({
    double size = 11,
    Color color = AppColors.ash,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: 1.0,
    );
  }

  static TextTheme textTheme() => darkTextTheme();

  static TextTheme darkTextTheme() {
    return GoogleFonts.manropeTextTheme().apply(
      bodyColor: AppColors.bone,
      displayColor: AppColors.bone,
    );
  }

  static TextTheme lightTextTheme() {
    return GoogleFonts.manropeTextTheme().apply(
      bodyColor: const Color(0xFF0A0A0E),
      displayColor: const Color(0xFF0A0A0E),
    );
  }
}
