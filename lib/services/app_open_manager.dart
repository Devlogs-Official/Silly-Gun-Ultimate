import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ad_ids.dart';
import '../core/ads/consent_manager.dart';
import '../core/config/app_config.dart';
import '../core/config/config_manager.dart';
import 'ad_event_logger.dart';

enum AppOpenAdShowResult { shown, disabled, notReady, failedToShow }

class AppOpenManager {
  AppOpenManager._();

  static final AppOpenManager instance = AppOpenManager._();
  static const Duration _maxCacheDuration = Duration(hours: 4);

  AppOpenAd? _appOpenAd;
  Completer<bool>? _loadCompleter;
  DateTime? _loadedAt;
  DateTime? _lastShownAt;
  DateTime? _backgroundAt;
  bool _isShowingAd = false;
  bool _suppressNextResume = false;

  bool get isShowingAd => _isShowingAd;

  void suppressNextResume() {
    _suppressNextResume = true;
    debugPrint('AppOpenManager: next resume app-open suppressed.');
  }

  void onPaused({required bool isShowingFullScreenAd}) {
    if (_suppressNextResume || isShowingFullScreenAd || _isShowingAd) {
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
    if (!config.showAppOpenOnResume || isShowingFullScreenAd || _isShowingAd) {
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

  Future<bool> loadAd({String placement = 'app_open_cache'}) {
    if (!_canRequestAppOpen) {
      debugPrint('AppOpenManager: app-open ads disabled.');
      _disposeLoadedAd();
      _loadCompleter = null;
      return Future<bool>.value(false);
    }
    if (_hasFreshAd) {
      return Future<bool>.value(true);
    }
    _disposeExpiredAd();
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    AdEventLogger.requested('app_open', placement: placement);
    final Completer<bool> loadCompleter = Completer<bool>();
    _loadCompleter = loadCompleter;

    AppOpenAd.load(
      adUnitId: AdIds.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          _loadedAt = DateTime.now();
          _loadCompleter = null;
          AdEventLogger.loaded('app_open', placement: placement);
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _appOpenAd = null;
          _loadedAt = null;
          _loadCompleter = null;
          AdEventLogger.failed('app_open', error, placement: placement);
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(false);
          }
        },
      ),
    );

    return loadCompleter.future;
  }

  Future<AppOpenAdShowResult> showAdIfAvailable({
    Duration loadTimeout = const Duration(seconds: 8),
    bool respectMinInterval = false,
    String placement = 'app_open',
  }) async {
    if (!_canRequestAppOpen) {
      debugPrint('AppOpenManager: app-open ads disabled.');
      return AppOpenAdShowResult.disabled;
    }
    if (_isShowingAd) {
      debugPrint('AppOpenManager: skipping while app-open is already showing.');
      return AppOpenAdShowResult.notReady;
    }
    if (respectMinInterval && !_hasPassedAppOpenInterval()) {
      debugPrint('AppOpenManager: app-open skipped by min interval.');
      return AppOpenAdShowResult.notReady;
    }

    _disposeExpiredAd();
    if (_appOpenAd == null) {
      final bool loaded = await loadAd(
        placement: placement,
      ).timeout(loadTimeout, onTimeout: () => false);
      if (!loaded || _appOpenAd == null) {
        debugPrint('AppOpenManager: app-open ad not ready.');
        return AppOpenAdShowResult.notReady;
      }
    }

    final AppOpenAd ad = _appOpenAd!;
    _appOpenAd = null;
    _loadedAt = null;
    final Completer<AppOpenAdShowResult> showCompleter =
        Completer<AppOpenAdShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        _isShowingAd = true;
        _lastShownAt = DateTime.now();
        AdEventLogger.shown('app_open', placement: placement);
      },
      onAdImpression: (Ad ad) {
        AdEventLogger.impression('app_open', placement: placement);
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        _isShowingAd = false;
        ad.dispose();
        AdEventLogger.dismissed('app_open', placement: placement);
        loadAd(placement: 'app_open_after_dismiss');
        if (!showCompleter.isCompleted) {
          showCompleter.complete(AppOpenAdShowResult.shown);
        }
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        _isShowingAd = false;
        ad.dispose();
        AdEventLogger.failedToShow('app_open', error, placement: placement);
        loadAd(placement: 'app_open_after_show_failure');
        if (!showCompleter.isCompleted) {
          showCompleter.complete(AppOpenAdShowResult.failedToShow);
        }
      },
    );

    try {
      _isShowingAd = true;
      await ad.show();
    } catch (error) {
      _isShowingAd = false;
      ad.dispose();
      debugPrint('AppOpenManager: app-open show threw: $error');
      loadAd(placement: 'app_open_after_show_exception');
      if (!showCompleter.isCompleted) {
        showCompleter.complete(AppOpenAdShowResult.failedToShow);
      }
    }

    return showCompleter.future;
  }

  void dispose() {
    _disposeLoadedAd();
    _loadCompleter = null;
    _backgroundAt = null;
  }

  bool get _canRequestAppOpen =>
      ConfigManager.config.showAds &&
      ConsentManager.canRequestAdsNow &&
      ConfigManager.config.showAppOpenAds &&
      AdIds.appOpenId.isNotEmpty;

  bool get _hasFreshAd {
    final DateTime? loadedAt = _loadedAt;
    return _appOpenAd != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _maxCacheDuration;
  }

  void _disposeExpiredAd() {
    if (_appOpenAd == null || _loadedAt == null) {
      return;
    }
    if (DateTime.now().difference(_loadedAt!) < _maxCacheDuration) {
      return;
    }
    debugPrint('AppOpenManager: cached app-open expired.');
    _disposeLoadedAd();
  }

  void _disposeLoadedAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _loadedAt = null;
  }

  bool _hasPassedAppOpenInterval() {
    final DateTime? lastShown = _lastShownAt;
    if (lastShown == null) {
      return true;
    }
    final int seconds = ConfigManager.config.appOpenMinIntervalSeconds;
    return DateTime.now().difference(lastShown) >= Duration(seconds: seconds);
  }
}
