import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppConfig {
  static const String legacyConfigJsonKey = 'silly_smile_gun_wallpaper_4K';

  static const String apiBaseUrlKey = 'api_base_url';
  static const String nativeIdKey = 'native_id';
  static const String interstitialIdKey = 'interstitial_id';
  static const String appOpenIdKey = 'app_open_id';
  static const String rewardedIdKey = 'rewarded_id';
  static const String collapsibleBannerIdKey = 'collapsible_banner_id';
  static const String showAdsKey = 'show_ads';
  static const String showNativeAdsKey = 'show_native_ads';
  static const String showInterstitialAdsKey = 'show_interstitial_ads';
  static const String showAppOpenAdsKey = 'show_app_open_ads';
  static const String showRewardedAdsKey = 'show_rewarded_ads';
  static const String gridNativeIntervalKey = 'grid_native_interval';
  static const String enableNativeAdsKey = 'enable_native_ads';
  static const String enableGridSquareNativeKey = 'enable_grid_square_native';
  static const String enableCollapsibleBannerKey = 'enable_collapsible_banner';
  static const String collapsibleBannerPositionKey =
      'collapsible_banner_position';
  static const String showNativeOnHomeScreenKey = 'show_native_on_home_screen';
  static const String showNativeInWallpaperGridKey =
      'show_native_in_wallpaper_grid';
  static const String showNativeOnFavoritesScreenKey =
      'show_native_on_favorites_screen';
  static const String showInterstitialOnApplyWallpaperKey =
      'show_interstitial_on_apply_wallpaper';
  static const String showRewardedOnLiveWallpaperUnlockKey =
      'show_rewarded_on_live_wallpaper_unlock';
  static const String showAppOpenOnColdStartKey = 'show_app_open_on_cold_start';
  static const String showAppOpenOnResumeKey = 'show_app_open_on_resume';
  static const String appOpenMinIntervalSecondsKey =
      'app_open_min_interval_seconds';
  static const String showShareTextOnStaticWallpaperKey =
      'show_share_text_on_static_wallpaper';
  static const String showShareTextOnLiveWallpaperKey =
      'show_share_text_on_live_wallpaper';
  static const String backgroundThresholdSecondsKey =
      'background_threshold_seconds';
  static const String persistUnlockedWallpapersKey =
      'persist_unlocked_wallpapers';

  final String apiBaseUrl;

  final String nativeId;
  final String interstitialId;
  final String appOpenId;
  final String rewardedId;
  final String collapsibleBannerId;

  final bool showAds;
  final bool showNativeAds;
  final bool showInterstitialAds;
  final bool showAppOpenAds;
  final bool showRewardedAds;
  final int gridNativeInterval;
  final bool enableNativeAds;
  final bool enableGridSquareNative;
  final bool enableCollapsibleBanner;
  final String collapsibleBannerPosition;
  final bool showNativeOnHomeScreen;
  final bool showNativeInWallpaperGrid;
  final bool showNativeOnFavoritesScreen;
  final bool showInterstitialOnApplyWallpaper;
  final bool showRewardedOnLiveWallpaperUnlock;
  final bool showAppOpenOnColdStart;
  final bool showAppOpenOnResume;
  final int appOpenMinIntervalSeconds;
  final bool showShareTextOnStaticWallpaper;
  final bool showShareTextOnLiveWallpaper;
  final int backgroundThresholdSeconds;
  final bool persistUnlockedWallpapers;

  const AppConfig({
    required this.apiBaseUrl,
    required this.nativeId,
    required this.interstitialId,
    required this.appOpenId,
    required this.rewardedId,
    required this.collapsibleBannerId,
    required this.showAds,
    required this.showNativeAds,
    required this.showInterstitialAds,
    required this.showAppOpenAds,
    required this.showRewardedAds,
    required this.gridNativeInterval,
    required this.enableNativeAds,
    required this.enableGridSquareNative,
    required this.enableCollapsibleBanner,
    required this.collapsibleBannerPosition,
    required this.showNativeOnHomeScreen,
    required this.showNativeInWallpaperGrid,
    required this.showNativeOnFavoritesScreen,
    required this.showInterstitialOnApplyWallpaper,
    required this.showRewardedOnLiveWallpaperUnlock,
    required this.showAppOpenOnColdStart,
    required this.showAppOpenOnResume,
    required this.appOpenMinIntervalSeconds,
    required this.showShareTextOnStaticWallpaper,
    required this.showShareTextOnLiveWallpaper,
    required this.backgroundThresholdSeconds,
    required this.persistUnlockedWallpapers,
  });

  static const AppConfig defaults = AppConfig(
    apiBaseUrl: '',
    nativeId: '',
    interstitialId: '',
    appOpenId: '',
    rewardedId: '',
    collapsibleBannerId: '',
    showAds: false,
    showNativeAds: false,
    showInterstitialAds: false,
    showAppOpenAds: false,
    showRewardedAds: false,
    gridNativeInterval: 10,
    enableNativeAds: false,
    enableGridSquareNative: true,
    enableCollapsibleBanner: true,
    collapsibleBannerPosition: 'bottom',
    showNativeOnHomeScreen: true,
    showNativeInWallpaperGrid: true,
    showNativeOnFavoritesScreen: true,
    showInterstitialOnApplyWallpaper: true,
    showRewardedOnLiveWallpaperUnlock: true,
    showAppOpenOnColdStart: true,
    showAppOpenOnResume: true,
    appOpenMinIntervalSeconds: 1800,
    showShareTextOnStaticWallpaper: true,
    showShareTextOnLiveWallpaper: true,
    backgroundThresholdSeconds: 1800,
    persistUnlockedWallpapers: false,
  );

  static Map<String, Object> get remoteDefaults => <String, Object>{
    legacyConfigJsonKey: '',
    apiBaseUrlKey: defaults.apiBaseUrl,
    nativeIdKey: defaults.nativeId,
    interstitialIdKey: defaults.interstitialId,
    appOpenIdKey: defaults.appOpenId,
    rewardedIdKey: defaults.rewardedId,
    collapsibleBannerIdKey: defaults.collapsibleBannerId,
    showAdsKey: defaults.showAds,
    showNativeAdsKey: defaults.showNativeAds,
    showInterstitialAdsKey: defaults.showInterstitialAds,
    showAppOpenAdsKey: defaults.showAppOpenAds,
    showRewardedAdsKey: defaults.showRewardedAds,
    gridNativeIntervalKey: defaults.gridNativeInterval,
    enableNativeAdsKey: defaults.enableNativeAds,
    enableGridSquareNativeKey: defaults.enableGridSquareNative,
    enableCollapsibleBannerKey: defaults.enableCollapsibleBanner,
    collapsibleBannerPositionKey: defaults.collapsibleBannerPosition,
    showNativeOnHomeScreenKey: defaults.showNativeOnHomeScreen,
    showNativeInWallpaperGridKey: defaults.showNativeInWallpaperGrid,
    showNativeOnFavoritesScreenKey: defaults.showNativeOnFavoritesScreen,
    showInterstitialOnApplyWallpaperKey:
        defaults.showInterstitialOnApplyWallpaper,
    showRewardedOnLiveWallpaperUnlockKey:
        defaults.showRewardedOnLiveWallpaperUnlock,
    showAppOpenOnColdStartKey: defaults.showAppOpenOnColdStart,
    showAppOpenOnResumeKey: defaults.showAppOpenOnResume,
    appOpenMinIntervalSecondsKey: defaults.appOpenMinIntervalSeconds,
    showShareTextOnStaticWallpaperKey: defaults.showShareTextOnStaticWallpaper,
    showShareTextOnLiveWallpaperKey: defaults.showShareTextOnLiveWallpaper,
    backgroundThresholdSecondsKey: defaults.backgroundThresholdSeconds,
    persistUnlockedWallpapersKey: defaults.persistUnlockedWallpapers,
  };

  factory AppConfig.fromRemoteConfig(FirebaseRemoteConfig remoteConfig) {
    final AppConfig fallback = AppConfig.defaults;
    final Map<String, dynamic> legacyConfig = _readLegacyConfig(remoteConfig);
    final Map<String, dynamic> legacyAds = _asMap(
      _asMap(legacyConfig['ads'])['android'],
    );
    final Map<String, dynamic> legacyFeatures = _asMap(
      legacyConfig['features'],
    );
    final Map<String, dynamic> legacyAdSettings = _asMap(
      legacyConfig['adSettings'],
    );
    final Map<String, dynamic> legacyUi = _asMap(legacyConfig['ui']);
    return AppConfig(
      apiBaseUrl: _readRemoteString(
        remoteConfig,
        apiBaseUrlKey,
        _readString(legacyConfig['apiBaseUrl'], fallback.apiBaseUrl),
      ),
      nativeId: _readRemoteString(
        remoteConfig,
        nativeIdKey,
        _readString(legacyAds['native'], fallback.nativeId),
      ),
      interstitialId: _readRemoteString(
        remoteConfig,
        interstitialIdKey,
        _readString(legacyAds['interstitial'], fallback.interstitialId),
      ),
      appOpenId: _readRemoteString(
        remoteConfig,
        appOpenIdKey,
        _readString(legacyAds['appOpen'], fallback.appOpenId),
      ),
      rewardedId: _readRemoteString(
        remoteConfig,
        rewardedIdKey,
        _readString(legacyAds['rewarded'], fallback.rewardedId),
      ),
      collapsibleBannerId: _readRemoteString(
        remoteConfig,
        collapsibleBannerIdKey,
        _readString(
          legacyAds['collapsibleBanner'],
          fallback.collapsibleBannerId,
        ),
      ),
      showAds: _readRemoteBool(
        remoteConfig,
        showAdsKey,
        _readBool(legacyFeatures['showAds'], fallback.showAds),
      ),
      showNativeAds: _readRemoteBool(
        remoteConfig,
        showNativeAdsKey,
        _readBool(legacyFeatures['showNativeAds'], fallback.showNativeAds),
      ),
      showInterstitialAds: _readRemoteBool(
        remoteConfig,
        showInterstitialAdsKey,
        _readBool(
          legacyFeatures['showInterstitialAds'],
          fallback.showInterstitialAds,
        ),
      ),
      showAppOpenAds: _readRemoteBool(
        remoteConfig,
        showAppOpenAdsKey,
        _readBool(legacyFeatures['showAppOpenAds'], fallback.showAppOpenAds),
      ),
      showRewardedAds: _readRemoteBool(
        remoteConfig,
        showRewardedAdsKey,
        _readBool(legacyFeatures['showRewardedAds'], fallback.showRewardedAds),
      ),
      gridNativeInterval: _readRemoteInt(
        remoteConfig,
        gridNativeIntervalKey,
        _readInt(
          legacyAdSettings['gridNativeInterval'],
          fallback.gridNativeInterval,
        ),
      ),
      enableNativeAds: _readRemoteBool(
        remoteConfig,
        enableNativeAdsKey,
        _readBool(
          legacyAdSettings['enableNativeAds'],
          fallback.enableNativeAds,
        ),
      ),
      enableGridSquareNative: _readRemoteBool(
        remoteConfig,
        enableGridSquareNativeKey,
        _readBool(
          legacyAdSettings['enableGridSquareNative'],
          fallback.enableGridSquareNative,
        ),
      ),
      enableCollapsibleBanner: _readRemoteBool(
        remoteConfig,
        enableCollapsibleBannerKey,
        _readBool(
          legacyAdSettings['enableCollapsibleBanner'],
          fallback.enableCollapsibleBanner,
        ),
      ),
      collapsibleBannerPosition: _readRemoteString(
        remoteConfig,
        collapsibleBannerPositionKey,
        _readString(
          legacyAdSettings['collapsibleBannerPosition'],
          fallback.collapsibleBannerPosition,
        ),
      ),
      showNativeOnHomeScreen: _readRemoteBool(
        remoteConfig,
        showNativeOnHomeScreenKey,
        _readBool(
          legacyAdSettings['showNativeOnHomeScreen'],
          fallback.showNativeOnHomeScreen,
        ),
      ),
      showNativeInWallpaperGrid: _readRemoteBool(
        remoteConfig,
        showNativeInWallpaperGridKey,
        _readBool(
          legacyAdSettings['showNativeInWallpaperGrid'],
          fallback.showNativeInWallpaperGrid,
        ),
      ),
      showNativeOnFavoritesScreen: _readRemoteBool(
        remoteConfig,
        showNativeOnFavoritesScreenKey,
        _readBool(
          legacyAdSettings['showNativeOnFavoritesScreen'],
          fallback.showNativeOnFavoritesScreen,
        ),
      ),
      showInterstitialOnApplyWallpaper: _readRemoteBool(
        remoteConfig,
        showInterstitialOnApplyWallpaperKey,
        _readBool(
          legacyAdSettings['showInterstitialOnApplyWallpaper'],
          fallback.showInterstitialOnApplyWallpaper,
        ),
      ),
      showRewardedOnLiveWallpaperUnlock: _readRemoteBool(
        remoteConfig,
        showRewardedOnLiveWallpaperUnlockKey,
        _readBool(
          legacyAdSettings['showRewardedOnLiveWallpaperUnlock'],
          fallback.showRewardedOnLiveWallpaperUnlock,
        ),
      ),
      showAppOpenOnColdStart: _readRemoteBool(
        remoteConfig,
        showAppOpenOnColdStartKey,
        _readBool(
          legacyAdSettings['showAppOpenOnColdStart'],
          fallback.showAppOpenOnColdStart,
        ),
      ),
      showAppOpenOnResume: _readRemoteBool(
        remoteConfig,
        showAppOpenOnResumeKey,
        _readBool(
          legacyAdSettings['showAppOpenOnResume'],
          fallback.showAppOpenOnResume,
        ),
      ),
      appOpenMinIntervalSeconds: _readRemoteInt(
        remoteConfig,
        appOpenMinIntervalSecondsKey,
        _readInt(
          legacyAdSettings['appOpenMinIntervalSeconds'],
          fallback.appOpenMinIntervalSeconds,
        ),
      ),
      showShareTextOnStaticWallpaper: _readRemoteBool(
        remoteConfig,
        showShareTextOnStaticWallpaperKey,
        _readBool(
          legacyUi['showShareTextOnStaticWallpaper'],
          fallback.showShareTextOnStaticWallpaper,
        ),
      ),
      showShareTextOnLiveWallpaper: _readRemoteBool(
        remoteConfig,
        showShareTextOnLiveWallpaperKey,
        _readBool(
          legacyUi['showShareTextOnLiveWallpaper'],
          fallback.showShareTextOnLiveWallpaper,
        ),
      ),
      backgroundThresholdSeconds: _readRemoteInt(
        remoteConfig,
        backgroundThresholdSecondsKey,
        _readInt(
          legacyAdSettings['backgroundThresholdSeconds'],
          fallback.backgroundThresholdSeconds,
        ),
      ),
      persistUnlockedWallpapers: _readRemoteBool(
        remoteConfig,
        persistUnlockedWallpapersKey,
        _readBool(
          legacyAdSettings['persistUnlockedWallpapers'],
          fallback.persistUnlockedWallpapers,
        ),
      ),
    );
  }

  static String _readRemoteString(
    FirebaseRemoteConfig remoteConfig,
    String key,
    String fallback,
  ) {
    final String value = remoteConfig.getString(key).trim();
    return value.isEmpty ? fallback : value;
  }

  static bool _readRemoteBool(
    FirebaseRemoteConfig remoteConfig,
    String key,
    bool fallback,
  ) {
    final RemoteConfigValue value = remoteConfig.getValue(key);
    return value.source == ValueSource.valueRemote ? value.asBool() : fallback;
  }

  static int _readRemoteInt(
    FirebaseRemoteConfig remoteConfig,
    String key,
    int fallback,
  ) {
    final RemoteConfigValue value = remoteConfig.getValue(key);
    return value.source == ValueSource.valueRemote ? value.asInt() : fallback;
  }

  static Map<String, dynamic> _readLegacyConfig(
    FirebaseRemoteConfig remoteConfig,
  ) {
    final String jsonString = remoteConfig.getString(legacyConfigJsonKey);
    if (jsonString.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final dynamic decoded = jsonDecode(jsonString);
      return _asMap(decoded);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic val) => MapEntry(key.toString(), val),
      );
    }
    return <String, dynamic>{};
  }

  static String _readString(dynamic value, String fallback) {
    final String? parsed = value?.toString().trim();
    if (parsed == null || parsed.isEmpty) {
      return fallback;
    }
    return parsed;
  }

  static bool _readBool(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final String normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }
}
