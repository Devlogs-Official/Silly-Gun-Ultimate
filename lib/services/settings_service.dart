import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

enum ApplyTarget { home, lock, both }

extension ApplyTargetX on ApplyTarget {
  int get wallpaperManagerLocation {
    switch (this) {
      case ApplyTarget.home:
        return WallpaperManagerPlus.homeScreen;
      case ApplyTarget.lock:
        return WallpaperManagerPlus.lockScreen;
      case ApplyTarget.both:
        return WallpaperManagerPlus.bothScreens;
    }
  }

  String get label {
    switch (this) {
      case ApplyTarget.home:
        return 'Home Screen';
      case ApplyTarget.lock:
        return 'Lock Screen';
      case ApplyTarget.both:
        return 'Both Screens';
    }
  }
}

enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get flutterMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

class SettingsService extends ChangeNotifier {
  static const String _applyTargetKey = 'apply_target';
  static const String _themeModeKey = 'theme_mode';

  static const ApplyTarget _defaultApplyTarget = ApplyTarget.both;
  static const AppThemeMode _defaultThemeMode = AppThemeMode.dark;

  ApplyTarget _applyTarget = _defaultApplyTarget;
  AppThemeMode _themeMode = _defaultThemeMode;
  bool _loaded = false;

  ApplyTarget get applyTarget => _applyTarget;
  AppThemeMode get themeMode => _themeMode;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _applyTarget = _parseApplyTarget(prefs.getString(_applyTargetKey));
    _themeMode = _parseThemeMode(prefs.getString(_themeModeKey));
    _loaded = true;
    notifyListeners();
  }

  Future<void> setApplyTarget(ApplyTarget target) async {
    if (_applyTarget == target) return;
    _applyTarget = target;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_applyTargetKey, target.name);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Toggle between light <-> dark. If currently following system, resolve
  /// based on the supplied current brightness then flip.
  Future<void> toggleLightDark(Brightness currentResolvedBrightness) async {
    if (_themeMode == AppThemeMode.system) {
      await setThemeMode(currentResolvedBrightness == Brightness.dark
          ? AppThemeMode.light
          : AppThemeMode.dark);
      return;
    }
    await setThemeMode(
      _themeMode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark,
    );
  }

  ApplyTarget _parseApplyTarget(String? raw) {
    if (raw == null) return _defaultApplyTarget;
    return ApplyTarget.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => _defaultApplyTarget,
    );
  }

  AppThemeMode _parseThemeMode(String? raw) {
    if (raw == null) return _defaultThemeMode;
    return AppThemeMode.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => _defaultThemeMode,
    );
  }
}
