import 'package:flutter/material.dart';

/// Theme-aware palette. Resolves the right surface, text, and hairline color
/// for the current Brightness via `context.palette.X`.
///
/// Crimson stays a constant via `AppColors.crimson` — it reads the same on
/// both themes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.ink,
    required this.obsidian,
    required this.graphite,
    required this.slate,
    required this.bone,
    required this.ash,
    required this.smoke,
    required this.hairline,
  });

  /// Lowest surface — full-screen background.
  final Color ink;

  /// Raised surface — cards.
  final Color obsidian;

  /// Higher surface — sub-cards and chips.
  final Color graphite;

  /// Highest surface — inputs / interactive chips.
  final Color slate;

  /// Primary text — high contrast.
  final Color bone;

  /// Secondary text — body / supporting.
  final Color ash;

  /// Tertiary text — hint / mono captions.
  final Color smoke;

  /// Hairline border.
  final Color hairline;

  static const AppPalette dark = AppPalette(
    ink: Color(0xFF0A0A0E),
    obsidian: Color(0xFF13141A),
    graphite: Color(0xFF1C1E28),
    slate: Color(0xFF262835),
    bone: Color(0xFFF5F1E8),
    ash: Color(0xFF8B8D9B),
    smoke: Color(0xFF5A5C6A),
    hairline: Color(0xFF26283A),
  );

  /// Light variant — bone canvas, ink type, beige hairlines.
  /// Same brutalist character as dark; magazine-paper feel rather than
  /// clinical Material white.
  static const AppPalette light = AppPalette(
    ink: Color(0xFFF7F2E6),
    obsidian: Color(0xFFFFFFFF),
    graphite: Color(0xFFF2EBD9),
    slate: Color(0xFFE8DFC8),
    bone: Color(0xFF0A0A0E),
    ash: Color(0xFF555560),
    smoke: Color(0xFF8E8B7E),
    hairline: Color(0xFFDFD6BD),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? dark;
  }

  @override
  AppPalette copyWith({
    Color? ink,
    Color? obsidian,
    Color? graphite,
    Color? slate,
    Color? bone,
    Color? ash,
    Color? smoke,
    Color? hairline,
  }) {
    return AppPalette(
      ink: ink ?? this.ink,
      obsidian: obsidian ?? this.obsidian,
      graphite: graphite ?? this.graphite,
      slate: slate ?? this.slate,
      bone: bone ?? this.bone,
      ash: ash ?? this.ash,
      smoke: smoke ?? this.smoke,
      hairline: hairline ?? this.hairline,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      obsidian: Color.lerp(obsidian, other.obsidian, t)!,
      graphite: Color.lerp(graphite, other.graphite, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
      bone: Color.lerp(bone, other.bone, t)!,
      ash: Color.lerp(ash, other.ash, t)!,
      smoke: Color.lerp(smoke, other.smoke, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => AppPalette.of(this);
}
