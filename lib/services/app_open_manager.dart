import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';

class AppOpenManager {
  AppOpenManager._();

  static final AppOpenManager instance = AppOpenManager._();

  bool _suppressNextResume = false;
  DateTime? _backgroundAt;

  void suppressNextResume() {
    _suppressNextResume = true;
    debugPrint('AppOpenManager: next resume app-open suppressed.');
  }

  void onPaused({required bool isShowingFullScreenAd}) {
    if (_suppressNextResume || isShowingFullScreenAd) {
      _backgroundAt = null;
      return;
    }
    _backgroundAt = DateTime.now();
  }

  bool shouldShowOnResume({
    required AppConfig config,
    required bool isShowingFullScreenAd,
  }) {
    if (_suppressNextResume) {
      _suppressNextResume = false;
      _backgroundAt = null;
      debugPrint('AppOpenManager: resume suppressed after full-screen ad.');
      return false;
    }
    if (!config.showAppOpenOnResume || isShowingFullScreenAd) {
      return false;
    }

    final DateTime? backgroundAt = _backgroundAt;
    _backgroundAt = null;
    if (backgroundAt == null) {
      return false;
    }

    final Duration timeInBackground = DateTime.now().difference(backgroundAt);
    final Duration threshold = Duration(
      seconds: config.backgroundThresholdSeconds,
    );
    if (timeInBackground < threshold) {
      debugPrint(
        'AppOpenManager: app-open skipped, background time '
            '${timeInBackground.inMilliseconds}ms < ${threshold.inMilliseconds}ms.',
      );
      return false;
    }

    return true;
  }
}