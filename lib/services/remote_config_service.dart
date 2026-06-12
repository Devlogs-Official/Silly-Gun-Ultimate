import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/config/config_manager.dart';

class RemoteConfigService {
  RemoteConfigService._();

  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static bool _isInitialized = false;
  static bool _isRefreshing = false;

  static Future<AppConfig> init() async {
    if (_isInitialized) {
      return ConfigManager.config;
    }

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 12),
        minimumFetchInterval:
        kDebugMode ? Duration.zero : const Duration(minutes: 30),
      ),
    );

    await _remoteConfig.setDefaults(AppConfig.remoteDefaults);

    _applyCurrentValues();
    await refreshInBackground();
    _isInitialized = true;
    return ConfigManager.config;
  }

  static Future<void> refreshInBackground() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    try {
      final bool activated = await _remoteConfig.fetchAndActivate();
      _applyCurrentValues();
      debugPrint(
        'Remote Config refreshed. Activated new values: $activated. '
            'showAds=${ConfigManager.config.showAds}, '
            'showRewardedAds=${ConfigManager.config.showRewardedAds}, '
            'rewardedIdEmpty=${ConfigManager.config.rewardedId.isEmpty}, '
            'rewardedId=${_safeAdUnitId(ConfigManager.config.rewardedId)}, '
            'collapsibleBannerId=${_safeAdUnitId(ConfigManager.config.collapsibleBannerId)}, '
            'backgroundThresholdSeconds=${ConfigManager.config.backgroundThresholdSeconds}',
      );
    } catch (error, stackTrace) {
      debugPrint('Remote Config refresh failed, using cached values: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isRefreshing = false;
    }
  }

  static void _applyCurrentValues() {
    ConfigManager.instance.update(AppConfig.fromRemoteConfig(_remoteConfig));
  }

  static String _safeAdUnitId(String adUnitId) {
    if (adUnitId.isEmpty) {
      return '<empty>';
    }
    final int visibleCount = adUnitId.length < 8 ? adUnitId.length : 8;
    return '...${adUnitId.substring(adUnitId.length - visibleCount)}';
  }
}