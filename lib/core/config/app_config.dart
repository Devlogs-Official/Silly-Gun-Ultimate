import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppConfig {
  static const String legacyConfigJsonKey = 'silly_smile_gun_wallpaper_4K';

  static const String apiBaseUrlKey = 'api_base_url';
  static const String bannerIdKey = 'banner_id';
  static const String interstitialIdKey = 'interstitial_id';
  static const String appOpenIdKey = 'app_open_id';
  static const String rewardedIdKey = 'rewarded_id';
  static const String collapsibleBannerIdKey = 'collapsible_banner_id';
  static const String showAdsKey = 'show_ads';
  static const String showInterstitialAdsKey = 'show_interstitial_ads';
  static const String showAppOpenAdsKey = 'show_app_open_ads';
  static const String showBannerAdsKey = 'show_banner_ads';
  static const String showRewardedAdsKey = 'show_rewarded_ads';
  static const String gridBannerIntervalKey = 'grid_banner_interval';
  static const String enableAdaptiveBannerKey = 'enable_adaptive_banner';
  static const String enableCollapsibleBannerKey = 'enable_collapsible_banner';
  static const String collapsibleBannerPositionKey =
      'collapsible_banner_position';
  static const String showBannerOnHomeScreenKey = 'show_banner_on_home_screen';
  static const String showBannerInWallpaperGridKey =
      'show_banner_in_wallpaper_grid';
  static const String showBannerOnFavoritesScreenKey =
      'show_banner_on_favorites_screen';
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
  static const String enableGridSquareBannerKey = 'enable_grid_square_banner';

  final String apiBaseUrl;

  final String bannerId;
  final String interstitialId;
  final String appOpenId;
  final String rewardedId;
  final String collapsibleBannerId;

  final bool showAds;
  final bool showInterstitialAds;
  final bool showAppOpenAds;
  final bool showBannerAds;
  final bool showRewardedAds;
  final int gridBannerInterval;
  final bool enableAdaptiveBanner;
  final bool enableCollapsibleBanner;
  final String collapsibleBannerPosition;
  final bool showBannerOnHomeScreen;
  final bool showBannerInWallpaperGrid;
  final bool showBannerOnFavoritesScreen;
  final bool showInterstitialOnApplyWallpaper;
  final bool showRewardedOnLiveWallpaperUnlock;
  final bool showAppOpenOnColdStart;
  final bool showAppOpenOnResume;
  final int appOpenMinIntervalSeconds;
  final bool showShareTextOnStaticWallpaper;
  final bool showShareTextOnLiveWallpaper;
  final int backgroundThresholdSeconds;
  final bool persistUnlockedWallpapers;
  final bool enableGridSquareBanner;

  const AppConfig({
    required this.apiBaseUrl,
    required this.bannerId,
    required this.interstitialId,
    required this.appOpenId,
    required this.rewardedId,
    required this.collapsibleBannerId,
    required this.showAds,
    required this.showInterstitialAds,
    required this.showAppOpenAds,
    required this.showBannerAds,
    required this.showRewardedAds,
    required this.gridBannerInterval,
    required this.enableAdaptiveBanner,
    required this.enableCollapsibleBanner,
    required this.collapsibleBannerPosition,
    required this.showBannerOnHomeScreen,
    required this.showBannerInWallpaperGrid,
    required this.showBannerOnFavoritesScreen,
    required this.showInterstitialOnApplyWallpaper,
    required this.showRewardedOnLiveWallpaperUnlock,
    required this.showAppOpenOnColdStart,
    required this.showAppOpenOnResume,
    required this.appOpenMinIntervalSeconds,
    required this.showShareTextOnStaticWallpaper,
    required this.showShareTextOnLiveWallpaper,
    required this.backgroundThresholdSeconds,
    required this.persistUnlockedWallpapers,
    required this.enableGridSquareBanner,
  });

  static const AppConfig defaults = AppConfig(
    apiBaseUrl: '',
    bannerId: '',
    interstitialId: '',
    appOpenId: '',
    rewardedId: '',
    collapsibleBannerId: '',
    showAds: false,
    showInterstitialAds: false,
    showAppOpenAds: false,
    showBannerAds: false,
    showRewardedAds: false,
    gridBannerInterval: 10,
    enableAdaptiveBanner: true,
    enableCollapsibleBanner: true,
    collapsibleBannerPosition: 'bottom',
    showBannerOnHomeScreen: true,
    showBannerInWallpaperGrid: true,
    showBannerOnFavoritesScreen: true,
    showInterstitialOnApplyWallpaper: true,
    showRewardedOnLiveWallpaperUnlock: true,
    showAppOpenOnColdStart: true,
    showAppOpenOnResume: true,
    appOpenMinIntervalSeconds: 1800,
    showShareTextOnStaticWallpaper: true,
    showShareTextOnLiveWallpaper: true,
    backgroundThresholdSeconds: 1800,
    persistUnlockedWallpapers: false,
    enableGridSquareBanner: false,
  );

  static Map<String, Object> get remoteDefaults => <String, Object>{
    legacyConfigJsonKey: '',
    apiBaseUrlKey: defaults.apiBaseUrl,
    bannerIdKey: defaults.bannerId,
    interstitialIdKey: defaults.interstitialId,
    appOpenIdKey: defaults.appOpenId,
    rewardedIdKey: defaults.rewardedId,
    collapsibleBannerIdKey: defaults.collapsibleBannerId,
    showAdsKey: defaults.showAds,
    showInterstitialAdsKey: defaults.showInterstitialAds,
    showAppOpenAdsKey: defaults.showAppOpenAds,
    showBannerAdsKey: defaults.showBannerAds,
    showRewardedAdsKey: defaults.showRewardedAds,
    gridBannerIntervalKey: defaults.gridBannerInterval,
    enableAdaptiveBannerKey: defaults.enableAdaptiveBanner,
    enableCollapsibleBannerKey: defaults.enableCollapsibleBanner,
    collapsibleBannerPositionKey: defaults.collapsibleBannerPosition,
    showBannerOnHomeScreenKey: defaults.showBannerOnHomeScreen,
    showBannerInWallpaperGridKey: defaults.showBannerInWallpaperGrid,
    showBannerOnFavoritesScreenKey: defaults.showBannerOnFavoritesScreen,
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
    enableGridSquareBannerKey: defaults.enableGridSquareBanner,
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
      bannerId: _readRemoteString(
        remoteConfig,
        bannerIdKey,
        _readString(legacyAds['banner'], fallback.bannerId),
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
      showBannerAds: _readRemoteBool(
        remoteConfig,
        showBannerAdsKey,
        _readBool(legacyFeatures['showBannerAds'], fallback.showBannerAds),
      ),
      showRewardedAds: _readRemoteBool(
        remoteConfig,
        showRewardedAdsKey,
        _readBool(legacyFeatures['showRewardedAds'], fallback.showRewardedAds),
      ),
      gridBannerInterval: _readRemoteInt(
        remoteConfig,
        gridBannerIntervalKey,
        _readInt(
          legacyAdSettings['gridBannerInterval'],
          fallback.gridBannerInterval,
        ),
      ),
      enableAdaptiveBanner: _readRemoteBool(
        remoteConfig,
        enableAdaptiveBannerKey,
        _readBool(
          legacyAdSettings['enableAdaptiveBanner'],
          fallback.enableAdaptiveBanner,
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
      showBannerOnHomeScreen: _readRemoteBool(
        remoteConfig,
        showBannerOnHomeScreenKey,
        _readBool(
          legacyAdSettings['showBannerOnHomeScreen'],
          fallback.showBannerOnHomeScreen,
        ),
      ),
      showBannerInWallpaperGrid: _readRemoteBool(
        remoteConfig,
        showBannerInWallpaperGridKey,
        _readBool(
          legacyAdSettings['showBannerInWallpaperGrid'],
          fallback.showBannerInWallpaperGrid,
        ),
      ),
      showBannerOnFavoritesScreen: _readRemoteBool(
        remoteConfig,
        showBannerOnFavoritesScreenKey,
        _readBool(
          legacyAdSettings['showBannerOnFavoritesScreen'],
          fallback.showBannerOnFavoritesScreen,
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
      enableGridSquareBanner: _readRemoteBool(
        remoteConfig,
        enableGridSquareBannerKey,
        _readBool(
          legacyAdSettings['enableGridSquareBanner'],
          fallback.enableGridSquareBanner,
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
