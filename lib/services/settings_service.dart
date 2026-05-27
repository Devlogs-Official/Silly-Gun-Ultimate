import 'package:flutter/foundation.dart';
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

class SettingsService extends ChangeNotifier {
  static const String _applyTargetKey = 'apply_target';
  static const ApplyTarget _defaultApplyTarget = ApplyTarget.both;

  ApplyTarget _applyTarget = _defaultApplyTarget;
  bool _loaded = false;

  ApplyTarget get applyTarget => _applyTarget;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_applyTargetKey);
    _applyTarget = _parse(stored);
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

  ApplyTarget _parse(String? raw) {
    if (raw == null) return _defaultApplyTarget;
    return ApplyTarget.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => _defaultApplyTarget,
    );
  }
}
