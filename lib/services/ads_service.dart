// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// import '../core/ad_ids.dart';
// import '../core/config/config_manager.dart';
// import 'app_open_manager.dart';
//
// enum InterstitialAdShowResult { shown, disabled, notReady, failedToShow }
//
// enum AppOpenAdShowResult { shown, disabled, notReady, failedToShow }
//
// enum RewardedAdShowResult {
//   rewarded,
//   dismissedWithoutReward,
//   disabled,
//   notReady,
//   failedToShow,
// }
//
// class AdService {
//   AdService._();
//
//   static InterstitialAd? _interstitialAd;
//   static AppOpenAd? _appOpenAd;
//   static RewardedAd? _rewardedAd;
//   static Future<InitializationStatus>? _mobileAdsInitialization;
//   static Future<void>? _requestConfigurationUpdate;
//   static Completer<bool>? _interstitialLoadCompleter;
//   static Completer<bool>? _appOpenLoadCompleter;
//   static Completer<bool>? _rewardedLoadCompleter;
//   static String? _lastRewardedLoadError;
//   static DateTime? _lastAppOpenShownAt;
//   static bool _isShowingFullScreenAd = false;
//   static final AdMetricsLogger metrics = AdMetricsLogger();
//
//   static bool get _canShowAds => ConfigManager.config.showAds;
//   static bool get _canShowInterstitialAds =>
//       _canShowAds && ConfigManager.config.showInterstitialAds;
//   static bool get _canShowAppOpenAds =>
//       _canShowAds && ConfigManager.config.showAppOpenAds;
//   static bool get _canShowBannerAds =>
//       _canShowAds && ConfigManager.config.showBannerAds;
//   static bool get _canShowRewardedAds =>
//       _canShowAds && ConfigManager.config.showRewardedAds;
//
//   static bool get isShowingFullScreenAd => _isShowingFullScreenAd;
//   static bool get isAppOpenAdAvailable => _appOpenAd != null;
//
//   static Future<void> initialize() async {
//     if (!Platform.isAndroid && !Platform.isIOS) {
//       return;
//     }
//
//     _requestConfigurationUpdate ??= MobileAds.instance
//         .updateRequestConfiguration(
//           RequestConfiguration(
//             /// Test device IDs for AdMob. Find your device ID in logcat by
//             /// searching for "Use RequestConfiguration.Builder().setTestDeviceIds".
//             testDeviceIds: <String>[
//               '9B9386F85AF0FC76B9DDB4A4E8622406',
//               'REPLACE_WITH_YOUR_DEVICE_ID',
//             ],
//           ),
//         );
//     await _requestConfigurationUpdate;
//     _mobileAdsInitialization ??= MobileAds.instance.initialize();
//     await _mobileAdsInitialization;
//     debugPrint('AdService: Mobile Ads initialized.');
//   }
//
//   static Future<bool> loadColdStartAppOpenAd() async {
//     await initialize();
//     debugPrint('AdService: Cold start app-open requested.');
//     return loadAppOpenAd();
//   }
//
//   static Future<bool> loadInterstitialAd() {
//     if (!_canShowInterstitialAds || AdIds.interstitialId.isEmpty) {
//       debugPrint('AdService: Interstitial ads disabled.');
//       _interstitialAd?.dispose();
//       _interstitialAd = null;
//       _interstitialLoadCompleter = null;
//       return Future<bool>.value(false);
//     }
//     if (_interstitialAd != null) {
//       return Future<bool>.value(true);
//     }
//     if (_interstitialLoadCompleter != null) {
//       return _interstitialLoadCompleter!.future;
//     }
//
//     debugPrint('AdService: Loading interstitial ad.');
//     metrics.recordRequest(AdFormatMetric.interstitial);
//     final Completer<bool> loadCompleter = Completer<bool>();
//     _interstitialLoadCompleter = loadCompleter;
//
//     InterstitialAd.load(
//       adUnitId: AdIds.interstitialId,
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (InterstitialAd ad) {
//           _interstitialAd = ad;
//           _interstitialLoadCompleter = null;
//           metrics.recordLoad(AdFormatMetric.interstitial);
//           debugPrint('AdService: Interstitial ad loaded.');
//           if (!loadCompleter.isCompleted) {
//             loadCompleter.complete(true);
//           }
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           debugPrint(
//             'AdService: Interstitial failed to load: ${error.message}',
//           );
//           metrics.recordFail(AdFormatMetric.interstitial);
//           _interstitialAd = null;
//           _interstitialLoadCompleter = null;
//           if (!loadCompleter.isCompleted) {
//             loadCompleter.complete(false);
//           }
//         },
//       ),
//     );
//
//     return loadCompleter.future;
//   }
//
//   static Future<InterstitialAdShowResult> showInterstitialAd({
//     Duration loadTimeout = const Duration(seconds: 8),
//   }) async {
//     if (!_canShowInterstitialAds || AdIds.interstitialId.isEmpty) {
//       debugPrint('AdService: Interstitial ads disabled.');
//       return InterstitialAdShowResult.disabled;
//     }
//
//     if (_interstitialAd == null) {
//       final bool loaded = await loadInterstitialAd().timeout(
//         loadTimeout,
//         onTimeout: () => false,
//       );
//       if (!loaded || _interstitialAd == null) {
//         debugPrint('AdService: Interstitial ad not ready.');
//         return InterstitialAdShowResult.notReady;
//       }
//     }
//
//     final InterstitialAd ad = _interstitialAd!;
//     _interstitialAd = null;
//     final Completer<InterstitialAdShowResult> showCompleter =
//         Completer<InterstitialAdShowResult>();
//
//     ad.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (Ad ad) {
//         AppOpenManager.instance.suppressNextResume();
//         metrics.recordShow(AdFormatMetric.interstitial);
//         debugPrint('AdService: Interstitial ad showed.');
//       },
//       onAdImpression: (Ad ad) {
//         metrics.recordImpression(AdFormatMetric.interstitial);
//       },
//       onAdDismissedFullScreenContent: (Ad ad) {
//         debugPrint('AdService: Interstitial ad dismissed.');
//         _isShowingFullScreenAd = false;
//         ad.dispose();
//         loadInterstitialAd();
//         if (!showCompleter.isCompleted) {
//           showCompleter.complete(InterstitialAdShowResult.shown);
//         }
//       },
//       onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
//         debugPrint('AdService: Interstitial failed to show: ${error.message}');
//         metrics.recordFail(AdFormatMetric.interstitial);
//         _isShowingFullScreenAd = false;
//         ad.dispose();
//         loadInterstitialAd();
//         if (!showCompleter.isCompleted) {
//           showCompleter.complete(InterstitialAdShowResult.failedToShow);
//         }
//       },
//     );
//
//     try {
//       AppOpenManager.instance.suppressNextResume();
//       _isShowingFullScreenAd = true;
//       await ad.show();
//     } catch (error) {
//       _isShowingFullScreenAd = false;
//       debugPrint('AdService: Interstitial show threw: $error');
//       ad.dispose();
//       loadInterstitialAd();
//       if (!showCompleter.isCompleted) {
//         showCompleter.complete(InterstitialAdShowResult.failedToShow);
//       }
//     }
//
//     return showCompleter.future;
//   }
//
//   static Future<BannerAd?> loadCollapsibleBannerAd({
//     required int width,
//     String placement = 'bottom',
//     BannerAdListener? listener,
//   }) async {
//     final String adUnitId = AdIds.collapsibleBannerId.isEmpty
//         ? AdIds.bannerId
//         : AdIds.collapsibleBannerId;
//     if (!_canShowBannerAds || adUnitId.isEmpty) {
//       debugPrint('AdService: Banner ads disabled.');
//       return null;
//     }
//
//     // The current collapsible banner guide requires standard anchored adaptive
//     // sizing; large anchored adaptive banners are not supported for this format.
//     final AnchoredAdaptiveBannerAdSize? size =
//         // ignore: deprecated_member_use
//         await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
//     if (size == null) {
//       debugPrint('AdService: Unable to resolve anchored adaptive banner size.');
//       return null;
//     }
//
//     final BannerAd bannerAd = BannerAd(
//       adUnitId: adUnitId,
//       size: size,
//       request: AdRequest(extras: <String, String>{'collapsible': placement}),
//       listener: listener ?? const BannerAdListener(),
//     );
//
//     metrics.recordRequest(AdFormatMetric.banner);
//     await bannerAd.load();
//     return bannerAd;
//   }
//
//   static Future<BannerAd?> loadAnchoredBannerAd({
//     required int width,
//     BannerAdListener? listener,
//   }) async {
//     if (!_canShowBannerAds || AdIds.bannerId.isEmpty) {
//       debugPrint('AdService: Banner ads disabled.');
//       return null;
//     }
//
//     final AdSize? size;
//     if (ConfigManager.config.enableAdaptiveBanner) {
//       size =
//           // ignore: deprecated_member_use
//           await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
//       if (size == null) {
//         debugPrint(
//           'AdService: Unable to resolve anchored adaptive banner size.',
//         );
//         return null;
//       }
//     } else {
//       size = AdSize.banner;
//     }
//
//     final BannerAd bannerAd = BannerAd(
//       adUnitId: AdIds.bannerId,
//       size: size,
//       request: const AdRequest(),
//       listener: listener ?? const BannerAdListener(),
//     );
//
//     metrics.recordRequest(AdFormatMetric.banner);
//     await bannerAd.load();
//     return bannerAd;
//   }
//
//   static Future<BannerAd?> loadMediumRectangleBannerAd({
//     BannerAdListener? listener,
//   }) async {
//     if (!_canShowBannerAds || AdIds.bannerId.isEmpty) {
//       debugPrint('AdService: Banner ads disabled.');
//       return null;
//     }
//
//     final BannerAd bannerAd = BannerAd(
//       adUnitId: AdIds.bannerId,
//       size: AdSize.mediumRectangle,
//       request: const AdRequest(),
//       listener: listener ?? const BannerAdListener(),
//     );
//
//     metrics.recordRequest(AdFormatMetric.banner);
//     await bannerAd.load();
//     return bannerAd;
//   }
//
//   static Future<bool> loadRewardedAd({Duration? loadTimeout}) {
//     if (!_canShowRewardedAds || AdIds.rewardedId.isEmpty) {
//       _lastRewardedLoadError =
//           'showAds=${ConfigManager.config.showAds}, '
//           'showRewardedAds=${ConfigManager.config.showRewardedAds}, '
//           'rewardedIdEmpty=${AdIds.rewardedId.isEmpty}';
//       debugPrint('AdService: Rewarded ads disabled. $_lastRewardedLoadError');
//       _rewardedAd?.dispose();
//       _rewardedAd = null;
//       _rewardedLoadCompleter = null;
//       return Future<bool>.value(false);
//     }
//     if (_rewardedAd != null) {
//       return Future<bool>.value(true);
//     }
//     if (_rewardedLoadCompleter != null) {
//       return _withRewardedLoadTimeout(
//         _rewardedLoadCompleter!.future,
//         loadTimeout,
//       );
//     }
//
//     debugPrint(
//       'AdService: Rewarded Requested. '
//       'adUnitId=${_safeAdUnitId(AdIds.rewardedId)}',
//     );
//     metrics.recordRequest(AdFormatMetric.rewarded);
//     _lastRewardedLoadError = null;
//     final Completer<bool> loadCompleter = Completer<bool>();
//     _rewardedLoadCompleter = loadCompleter;
//
//     RewardedAd.load(
//       adUnitId: AdIds.rewardedId,
//       request: const AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (RewardedAd ad) {
//           _rewardedAd = ad;
//           _rewardedLoadCompleter = null;
//           _lastRewardedLoadError = null;
//           metrics.recordLoad(AdFormatMetric.rewarded);
//           debugPrint('AdService: Rewarded Loaded.');
//           if (!loadCompleter.isCompleted) {
//             loadCompleter.complete(true);
//           }
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           _lastRewardedLoadError =
//               'code=${error.code}, domain=${error.domain}, '
//               'message=${error.message}';
//           metrics.recordFail(AdFormatMetric.rewarded);
//           debugPrint('AdService: Rewarded Failed. $_lastRewardedLoadError');
//           _rewardedAd = null;
//           _rewardedLoadCompleter = null;
//           if (!loadCompleter.isCompleted) {
//             loadCompleter.complete(false);
//           }
//         },
//       ),
//     );
//
//     return _withRewardedLoadTimeout(loadCompleter.future, loadTimeout);
//   }
//
//   static Future<bool> _withRewardedLoadTimeout(
//     Future<bool> future,
//     Duration? loadTimeout,
//   ) {
//     if (loadTimeout == null) {
//       return future;
//     }
//     return future.timeout(
//       loadTimeout,
//       onTimeout: () {
//         _rewardedLoadCompleter = null;
//         _lastRewardedLoadError = 'Load timed out after $loadTimeout.';
//         return false;
//       },
//     );
//   }
//
//   static Future<RewardedAdShowResult> showRewardedAd({
//     Duration loadTimeout = const Duration(seconds: 90),
//   }) async {
//     if (!_canShowRewardedAds || AdIds.rewardedId.isEmpty) {
//       debugPrint('AdService: Rewarded ads disabled.');
//       return RewardedAdShowResult.disabled;
//     }
//
//     if (_rewardedAd == null) {
//       final bool loaded = await loadRewardedAd(loadTimeout: loadTimeout);
//       if (!loaded || _rewardedAd == null) {
//         debugPrint(
//           'AdService: Rewarded ad not ready. '
//           '${_lastRewardedLoadError ?? 'Load timed out or no callback yet.'}',
//         );
//         return RewardedAdShowResult.notReady;
//       }
//     }
//
//     final RewardedAd ad = _rewardedAd!;
//     _rewardedAd = null;
//     bool earnedReward = false;
//     final Completer<RewardedAdShowResult> showCompleter =
//         Completer<RewardedAdShowResult>();
//
//     ad.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (Ad ad) {
//         AppOpenManager.instance.suppressNextResume();
//         metrics.recordShow(AdFormatMetric.rewarded);
//         debugPrint('AdService: Rewarded Shown.');
//       },
//       onAdImpression: (Ad ad) {
//         metrics.recordImpression(AdFormatMetric.rewarded);
//       },
//       onAdDismissedFullScreenContent: (Ad ad) {
//         debugPrint('AdService: Rewarded Dismissed.');
//         _isShowingFullScreenAd = false;
//         ad.dispose();
//         if (!showCompleter.isCompleted) {
//           showCompleter.complete(
//             earnedReward
//                 ? RewardedAdShowResult.rewarded
//                 : RewardedAdShowResult.dismissedWithoutReward,
//           );
//         }
//       },
//       onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
//         debugPrint('AdService: Rewarded failed to show: ${error.message}');
//         metrics.recordFail(AdFormatMetric.rewarded);
//         _isShowingFullScreenAd = false;
//         ad.dispose();
//         if (!showCompleter.isCompleted) {
//           showCompleter.complete(RewardedAdShowResult.failedToShow);
//         }
//       },
//     );
//
//     try {
//       AppOpenManager.instance.suppressNextResume();
//       _isShowingFullScreenAd = true;
//       await ad.show(
//         onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
//           debugPrint(
//             'AdService: Reward Earned: ${reward.amount} ${reward.type}',
//           );
//           earnedReward = true;
//         },
//       );
//     } catch (error) {
//       _isShowingFullScreenAd = false;
//       debugPrint('AdService: Rewarded show threw: $error');
//       metrics.recordFail(AdFormatMetric.rewarded);
//       ad.dispose();
//       if (!showCompleter.isCompleted) {
//         showCompleter.complete(RewardedAdShowResult.failedToShow);
//       }
//     }
//
//     return showCompleter.future;
//   }
//
//   static Future<bool> loadAppOpenAd() {
//     if (!_canShowAppOpenAds || AdIds.appOpenId.isEmpty) {
//       debugPrint('AdService: App open ads disabled.');
//       _appOpenAd?.dispose();
//       _appOpenAd = null;
//       _appOpenLoadCompleter = null;
//       return Future<bool>.value(false);
//     }
//     if (_appOpenAd != null) {
//       return Future<bool>.value(true);
//     }
//     if (_appOpenLoadCompleter != null) {
//       return _appOpenLoadCompleter!.future;
//     }
//
//     debugPrint('AdService: Loading app open ad.');
//     metrics.recordRequest(AdFormatMetric.appOpen);
//     final Completer<bool> loadCompleter = Completer<bool>();
//     _appOpenLoadCompleter = loadCompleter;
//
//     AppOpenAd.load(
//       adUnitId: AdIds.appOpenId,
//       request: const AdRequest(),
//       adLoadCallback: AppOpenAdLoadCallback(
//         onAdLoaded: (AppOpenAd ad) {
//           _appOpenAd = ad;
//           _appOpenLoadCompleter = null;
//           metrics.recordLoad(AdFormatMetric.appOpen);
//           debugPrint('AdService: App open ad loaded.');
//           if (!loadCompleter.isCompleted) {
//             loadCompleter.complete(true);
//           }
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           debugPrint('AdService: App open failed to load: ${error.message}');
//           metrics.recordFail(AdFormatMetric.appOpen);
//           _appOpenAd = null;
//           _appOpenLoadCompleter = null;
//           if (!loadCompleter.isCompleted) {
//             loadCompleter.complete(false);
//           }
//         },
//       ),
//     );
//
//     return loadCompleter.future;
//   }
//
//   static Future<AppOpenAdShowResult> showAppOpenAdAndWait({
//     Duration loadTimeout = const Duration(seconds: 8),
//     bool respectMinInterval = false,
//   }) async {
//     if (!_canShowAppOpenAds || AdIds.appOpenId.isEmpty) {
//       debugPrint('AdService: App open ads disabled.');
//       return AppOpenAdShowResult.disabled;
//     }
//     if (_isShowingFullScreenAd) {
//       debugPrint('AdService: Skipping app open while another ad is showing.');
//       return AppOpenAdShowResult.notReady;
//     }
//     if (respectMinInterval && !_hasPassedAppOpenInterval()) {
//       debugPrint('AdService: App open skipped by min interval.');
//       return AppOpenAdShowResult.notReady;
//     }
//
//     if (_appOpenAd == null) {
//       final bool loaded = await loadAppOpenAd().timeout(
//         loadTimeout,
//         onTimeout: () => false,
//       );
//       if (!loaded || _appOpenAd == null) {
//         debugPrint('AdService: App open ad not ready.');
//         return AppOpenAdShowResult.notReady;
//       }
//     }
//
//     final AppOpenAd ad = _appOpenAd!;
//     _appOpenAd = null;
//     final Completer<AppOpenAdShowResult> showCompleter =
//         Completer<AppOpenAdShowResult>();
//
//     ad.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (Ad ad) {
//         debugPrint('AdService: App open ad showed.');
//         metrics.recordShow(AdFormatMetric.appOpen);
//         _lastAppOpenShownAt = DateTime.now();
//       },
//       onAdImpression: (Ad ad) {
//         metrics.recordImpression(AdFormatMetric.appOpen);
//       },
//       onAdDismissedFullScreenContent: (Ad ad) {
//         debugPrint('AdService: App open ad dismissed.');
//         _isShowingFullScreenAd = false;
//         ad.dispose();
//         loadAppOpenAd();
//         if (!showCompleter.isCompleted) {
//           showCompleter.complete(AppOpenAdShowResult.shown);
//         }
//       },
//       onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
//         debugPrint('AdService: App open failed to show: ${error.message}');
//         metrics.recordFail(AdFormatMetric.appOpen);
//         _isShowingFullScreenAd = false;
//         ad.dispose();
//         loadAppOpenAd();
//         if (!showCompleter.isCompleted) {
//           showCompleter.complete(AppOpenAdShowResult.failedToShow);
//         }
//       },
//     );
//
//     try {
//       _isShowingFullScreenAd = true;
//       await ad.show();
//     } catch (error) {
//       _isShowingFullScreenAd = false;
//       debugPrint('AdService: App open show threw: $error');
//       metrics.recordFail(AdFormatMetric.appOpen);
//       ad.dispose();
//       loadAppOpenAd();
//       if (!showCompleter.isCompleted) {
//         showCompleter.complete(AppOpenAdShowResult.failedToShow);
//       }
//     }
//
//     return showCompleter.future;
//   }
//
//   static bool _hasPassedAppOpenInterval() {
//     final DateTime? lastShown = _lastAppOpenShownAt;
//     if (lastShown == null) {
//       return true;
//     }
//     final int seconds = ConfigManager.config.appOpenMinIntervalSeconds;
//     return DateTime.now().difference(lastShown) >= Duration(seconds: seconds);
//   }
//
//   static void dispose() {
//     debugPrint('AdService: Disposing loaded ads.');
//     _interstitialAd?.dispose();
//     _appOpenAd?.dispose();
//     _rewardedAd?.dispose();
//     _interstitialAd = null;
//     _appOpenAd = null;
//     _rewardedAd = null;
//     _interstitialLoadCompleter = null;
//     _appOpenLoadCompleter = null;
//     _rewardedLoadCompleter = null;
//   }
//
//   static String _safeAdUnitId(String adUnitId) {
//     if (adUnitId.isEmpty) {
//       return '<empty>';
//     }
//     final int visibleCount = adUnitId.length < 8 ? adUnitId.length : 8;
//     return '...${adUnitId.substring(adUnitId.length - visibleCount)}';
//   }
// }
//
// enum AdFormatMetric { appOpen, interstitial, rewarded, banner }
//
// class AdMetricsLogger {
//   final Map<AdFormatMetric, _AdMetricCounter> _counters =
//       <AdFormatMetric, _AdMetricCounter>{
//         for (final AdFormatMetric format in AdFormatMetric.values)
//           format: _AdMetricCounter(),
//       };
//
//   void recordRequest(AdFormatMetric format) {
//     _counters[format]!.requests++;
//     _log(format);
//   }
//
//   void recordLoad(AdFormatMetric format) {
//     _counters[format]!.loads++;
//     _log(format);
//   }
//
//   void recordFail(AdFormatMetric format) {
//     _counters[format]!.fails++;
//     _log(format);
//   }
//
//   void recordShow(AdFormatMetric format) {
//     _counters[format]!.shows++;
//     _log(format);
//   }
//
//   void recordImpression(AdFormatMetric format) {
//     _counters[format]!.impressions++;
//     _log(format);
//   }
//
//   String report() {
//     return AdFormatMetric.values
//         .map((AdFormatMetric format) {
//           final _AdMetricCounter counter = _counters[format]!;
//           return '${_formatName(format)}: requests=${counter.requests}, '
//               'loads=${counter.loads}, fails=${counter.fails}, '
//               'shows=${counter.shows}, impressions=${counter.impressions}, '
//               'matchRate=${counter.matchRate.toStringAsFixed(1)}%, '
//               'showRate=${counter.showRate.toStringAsFixed(1)}%';
//         })
//         .join(' | ');
//   }
//
//   void _log(AdFormatMetric format) {
//     final _AdMetricCounter counter = _counters[format]!;
//     debugPrint(
//       'AdMetrics ${_formatName(format)}: requests=${counter.requests}, '
//       'loads=${counter.loads}, fails=${counter.fails}, shows=${counter.shows}, '
//       'impressions=${counter.impressions}, '
//       'matchRate=${counter.matchRate.toStringAsFixed(1)}%, '
//       'showRate=${counter.showRate.toStringAsFixed(1)}%',
//     );
//   }
//
//   String _formatName(AdFormatMetric format) {
//     switch (format) {
//       case AdFormatMetric.appOpen:
//         return 'app_open';
//       case AdFormatMetric.interstitial:
//         return 'interstitial';
//       case AdFormatMetric.rewarded:
//         return 'rewarded';
//       case AdFormatMetric.banner:
//         return 'banner';
//     }
//   }
// }
//
// class _AdMetricCounter {
//   int requests = 0;
//   int loads = 0;
//   int fails = 0;
//   int shows = 0;
//   int impressions = 0;
//
//   double get matchRate => requests == 0 ? 0 : loads / requests * 100;
//
//   double get showRate => loads == 0 ? 0 : shows / loads * 100;
// }
//
// class BannerAdWidget extends StatefulWidget {
//   const BannerAdWidget({
//     super.key,
//     this.collapsible = true,
//     this.horizontalPadding = 0,
//     this.mediumRectangle = false,
//     this.onLoadStateChanged,
//   });
//
//   final bool collapsible;
//   final double horizontalPadding;
//   final bool mediumRectangle;
//   final ValueChanged<bool>? onLoadStateChanged;
//
//   @override
//   State<BannerAdWidget> createState() => _BannerAdWidgetState();
// }
//
// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _bannerAd;
//   bool _isAdLoaded = false;
//   int? _loadedWidth;
//   bool _didFallbackFromCollapsible = false;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final int width =
//         (MediaQuery.sizeOf(context).width - widget.horizontalPadding)
//             .truncate();
//     if (_loadedWidth != width) {
//       _loadedWidth = width;
//       _loadBannerAd(width);
//     }
//   }
//
//   Future<void> _loadBannerAd(int width) async {
//     _bannerAd?.dispose();
//     _bannerAd = null;
//     _didFallbackFromCollapsible = false;
//     widget.onLoadStateChanged?.call(false);
//     if (mounted) {
//       setState(() => _isAdLoaded = false);
//     }
//
//     final bool shouldRequestCollapsible =
//         !widget.mediumRectangle &&
//         widget.collapsible &&
//         ConfigManager.config.enableCollapsibleBanner;
//     final BannerAd? bannerAd = await (widget.mediumRectangle
//         ? AdService.loadMediumRectangleBannerAd(listener: _bannerAdListener())
//         : shouldRequestCollapsible
//         ? AdService.loadCollapsibleBannerAd(
//             width: width,
//             placement: ConfigManager.config.collapsibleBannerPosition,
//             listener: _bannerAdListener(),
//           )
//         : AdService.loadAnchoredBannerAd(
//             width: width,
//             listener: _bannerAdListener(),
//           ));
//
//     if (bannerAd == null) {
//       widget.onLoadStateChanged?.call(false);
//       return;
//     }
//     if (!mounted) {
//       bannerAd.dispose();
//       return;
//     }
//   }
//
//   BannerAdListener _bannerAdListener() {
//     return BannerAdListener(
//       onAdLoaded: (Ad ad) {
//         final BannerAd bannerAd = ad as BannerAd;
//         AdService.metrics.recordLoad(AdFormatMetric.banner);
//         debugPrint(
//           'BannerAdWidget: Banner loaded. Collapsible: ${bannerAd.isCollapsible}',
//         );
//         if (!mounted) {
//           ad.dispose();
//           return;
//         }
//         setState(() {
//           _bannerAd = bannerAd;
//           _isAdLoaded = true;
//         });
//         widget.onLoadStateChanged?.call(true);
//       },
//       onAdFailedToLoad: (Ad ad, LoadAdError error) {
//         debugPrint('BannerAdWidget: Banner failed: ${error.message}');
//         AdService.metrics.recordFail(AdFormatMetric.banner);
//         ad.dispose();
//         if (widget.collapsible &&
//             ConfigManager.config.enableCollapsibleBanner &&
//             !_didFallbackFromCollapsible &&
//             _loadedWidth != null) {
//           _didFallbackFromCollapsible = true;
//           AdService.loadAnchoredBannerAd(
//             width: _loadedWidth!,
//             listener: _bannerAdListener(),
//           );
//           return;
//         }
//         if (mounted) {
//           setState(() => _isAdLoaded = false);
//         }
//         widget.onLoadStateChanged?.call(false);
//       },
//       onAdImpression: (Ad ad) {
//         AdService.metrics.recordShow(AdFormatMetric.banner);
//         AdService.metrics.recordImpression(AdFormatMetric.banner);
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _bannerAd?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_isAdLoaded || _bannerAd == null) {
//       return const SizedBox.shrink();
//     }
//
//     return SizedBox(
//       width: widget.mediumRectangle
//           ? double.infinity
//           : _bannerAd!.size.width.toDouble(),
//       height: _bannerAd!.size.height.toDouble(),
//       child: Center(
//         child: SizedBox(
//           width: _bannerAd!.size.width.toDouble(),
//           height: _bannerAd!.size.height.toDouble(),
//           child: AdWidget(ad: _bannerAd!),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/ad_ids.dart';
import '../core/config/config_manager.dart';
import 'ad_event_logger.dart';
import 'app_open_manager.dart';

enum InterstitialAdShowResult { shown, disabled, notReady, failedToShow }

enum RewardedAdShowResult {
  rewarded,
  dismissedWithoutReward,
  disabled,
  notReady,
  failedToShow,
}

class AdService {
  AdService._();

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static Completer<bool>? _interstitialLoadCompleter;
  static Completer<bool>? _rewardedLoadCompleter;
  static String? _lastRewardedLoadError;
  static bool _isShowingFullScreenAd = false;

  static bool get _canShowAds => ConfigManager.config.showAds;
  static bool get _canShowInterstitialAds =>
      _canShowAds && ConfigManager.config.showInterstitialAds;
  static bool get _canShowBannerAds =>
      _canShowAds && ConfigManager.config.showBannerAds;
  static bool get _canShowRewardedAds =>
      _canShowAds && ConfigManager.config.showRewardedAds;

  static bool get isShowingFullScreenAd =>
      _isShowingFullScreenAd || AppOpenManager.instance.isShowingAd;

  static Future<bool> loadInterstitialAd() {
    if (!_canShowInterstitialAds || AdIds.interstitialId.isEmpty) {
      debugPrint('AdService: Interstitial ads disabled.');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _interstitialLoadCompleter = null;
      return Future<bool>.value(false);
    }
    if (_interstitialAd != null) {
      return Future<bool>.value(true);
    }
    if (_interstitialLoadCompleter != null) {
      return _interstitialLoadCompleter!.future;
    }

    AdEventLogger.requested('interstitial', placement: 'preload');
    final Completer<bool> loadCompleter = Completer<bool>();
    _interstitialLoadCompleter = loadCompleter;

    InterstitialAd.load(
      adUnitId: AdIds.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadCompleter = null;
          AdEventLogger.loaded('interstitial', placement: 'preload');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          AdEventLogger.failed('interstitial', error, placement: 'preload');
          _interstitialAd = null;
          _interstitialLoadCompleter = null;
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(false);
          }
        },
      ),
    );

    return loadCompleter.future;
  }

  static Future<InterstitialAdShowResult> showInterstitialAd({
    Duration loadTimeout = const Duration(seconds: 8),
  }) async {
    if (!_canShowInterstitialAds || AdIds.interstitialId.isEmpty) {
      debugPrint('AdService: Interstitial ads disabled.');
      return InterstitialAdShowResult.disabled;
    }

    if (_interstitialAd == null) {
      final bool loaded = await loadInterstitialAd().timeout(
        loadTimeout,
        onTimeout: () => false,
      );
      if (!loaded || _interstitialAd == null) {
        debugPrint('AdService: Interstitial ad not ready.');
        return InterstitialAdShowResult.notReady;
      }
    }

    final InterstitialAd ad = _interstitialAd!;
    _interstitialAd = null;
    final Completer<InterstitialAdShowResult> showCompleter =
    Completer<InterstitialAdShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        AppOpenManager.instance.suppressNextResume();
        AdEventLogger.shown('interstitial', placement: 'apply_wallpaper');
      },
      onAdImpression: (Ad ad) {
        AdEventLogger.impression('interstitial', placement: 'apply_wallpaper');
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        AdEventLogger.dismissed('interstitial', placement: 'apply_wallpaper');
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadInterstitialAd();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(InterstitialAdShowResult.shown);
        }
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        AdEventLogger.failedToShow(
          'interstitial',
          error,
          placement: 'apply_wallpaper',
        );
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadInterstitialAd();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(InterstitialAdShowResult.failedToShow);
        }
      },
    );

    try {
      AppOpenManager.instance.suppressNextResume();
      _isShowingFullScreenAd = true;
      await ad.show();
    } catch (error) {
      _isShowingFullScreenAd = false;
      debugPrint('AdService: Interstitial show threw: $error');
      ad.dispose();
      loadInterstitialAd();
      if (!showCompleter.isCompleted) {
        showCompleter.complete(InterstitialAdShowResult.failedToShow);
      }
    }

    return showCompleter.future;
  }

  static Future<BannerAd?> loadCollapsibleBannerAd({
    required int width,
    String placement = 'bottom',
    BannerAdListener? listener,
  }) async {
    final String adUnitId = AdIds.collapsibleBannerId.isEmpty
        ? AdIds.bannerId
        : AdIds.collapsibleBannerId;
    if (!_canShowBannerAds || adUnitId.isEmpty) {
      debugPrint('AdService: Banner ads disabled.');
      return null;
    }

    // The current collapsible banner guide requires standard anchored adaptive
    // sizing; large anchored adaptive banners are not supported for this format.
    final AnchoredAdaptiveBannerAdSize? size =
    // ignore: deprecated_member_use
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null) {
      debugPrint('AdService: Unable to resolve anchored adaptive banner size.');
      return null;
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: AdRequest(extras: <String, String>{'collapsible': placement}),
      listener: listener ?? const BannerAdListener(),
    );

    AdEventLogger.requested('banner_collapsible', placement: placement);
    await bannerAd.load();
    return bannerAd;
  }

  static Future<BannerAd?> loadAnchoredBannerAd({
    required int width,
    BannerAdListener? listener,
  }) async {
    if (!_canShowBannerAds || AdIds.bannerId.isEmpty) {
      debugPrint('AdService: Banner ads disabled.');
      return null;
    }

    final AdSize? size;
    if (ConfigManager.config.enableAdaptiveBanner) {
      size =
      // ignore: deprecated_member_use
      await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null) {
        debugPrint(
          'AdService: Unable to resolve anchored adaptive banner size.',
        );
        return null;
      }
    } else {
      size = AdSize.banner;
    }

    AdEventLogger.requested('banner', placement: 'anchored');
    final BannerAd bannerAd = BannerAd(
      adUnitId: AdIds.bannerId,
      size: size,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );

    await bannerAd.load();
    return bannerAd;
  }

  static Future<BannerAd?> loadMediumRectangleBannerAd({
    BannerAdListener? listener,
  }) async {
    if (!_canShowBannerAds || AdIds.bannerId.isEmpty) {
      debugPrint('AdService: Banner ads disabled.');
      return null;
    }

    AdEventLogger.requested('banner', placement: 'medium_rectangle');
    final BannerAd bannerAd = BannerAd(
      adUnitId: AdIds.bannerId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );

    await bannerAd.load();
    return bannerAd;
  }

  static Future<bool> loadRewardedAd({Duration? loadTimeout}) {
    if (!_canShowRewardedAds || AdIds.rewardedId.isEmpty) {
      _lastRewardedLoadError =
      'showAds=${ConfigManager.config.showAds}, '
          'showRewardedAds=${ConfigManager.config.showRewardedAds}, '
          'rewardedIdEmpty=${AdIds.rewardedId.isEmpty}';
      debugPrint('AdService: Rewarded ads disabled. $_lastRewardedLoadError');
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _rewardedLoadCompleter = null;
      return Future<bool>.value(false);
    }
    if (_rewardedAd != null) {
      return Future<bool>.value(true);
    }
    if (_rewardedLoadCompleter != null) {
      return _withRewardedLoadTimeout(
        _rewardedLoadCompleter!.future,
        loadTimeout,
      );
    }

    AdEventLogger.requested('rewarded', placement: 'live_wallpaper_unlock');
    _lastRewardedLoadError = null;
    final Completer<bool> loadCompleter = Completer<bool>();
    _rewardedLoadCompleter = loadCompleter;

    RewardedAd.load(
      adUnitId: AdIds.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _rewardedLoadCompleter = null;
          _lastRewardedLoadError = null;
          AdEventLogger.loaded('rewarded', placement: 'live_wallpaper_unlock');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _lastRewardedLoadError =
          'code=${error.code}, domain=${error.domain}, '
              'message=${error.message}';
          AdEventLogger.failed(
            'rewarded',
            error,
            placement: 'live_wallpaper_unlock',
          );
          _rewardedAd = null;
          _rewardedLoadCompleter = null;
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(false);
          }
        },
      ),
    );

    return _withRewardedLoadTimeout(loadCompleter.future, loadTimeout);
  }

  static Future<bool> _withRewardedLoadTimeout(
      Future<bool> future,
      Duration? loadTimeout,
      ) {
    if (loadTimeout == null) {
      return future;
    }
    return future.timeout(
      loadTimeout,
      onTimeout: () {
        _rewardedLoadCompleter = null;
        _lastRewardedLoadError = 'Load timed out after $loadTimeout.';
        return false;
      },
    );
  }

  static Future<RewardedAdShowResult> showRewardedAd({
    Duration loadTimeout = const Duration(seconds: 30),
  }) async {
    if (!_canShowRewardedAds || AdIds.rewardedId.isEmpty) {
      debugPrint('AdService: Rewarded ads disabled.');
      return RewardedAdShowResult.disabled;
    }

    if (_rewardedAd == null) {
      final bool loaded = await loadRewardedAd(loadTimeout: loadTimeout);
      if (!loaded || _rewardedAd == null) {
        debugPrint(
          'AdService: Rewarded ad not ready. '
              '${_lastRewardedLoadError ?? 'Load timed out or no callback yet.'}',
        );
        return RewardedAdShowResult.notReady;
      }
    }

    final RewardedAd ad = _rewardedAd!;
    _rewardedAd = null;
    bool earnedReward = false;
    final Completer<RewardedAdShowResult> showCompleter =
    Completer<RewardedAdShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        AppOpenManager.instance.suppressNextResume();
        AdEventLogger.shown('rewarded', placement: 'live_wallpaper_unlock');
      },
      onAdImpression: (Ad ad) {
        AdEventLogger.impression(
          'rewarded',
          placement: 'live_wallpaper_unlock',
        );
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        AdEventLogger.dismissed('rewarded', placement: 'live_wallpaper_unlock');
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadRewardedAd();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(
            earnedReward
                ? RewardedAdShowResult.rewarded
                : RewardedAdShowResult.dismissedWithoutReward,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        AdEventLogger.failedToShow(
          'rewarded',
          error,
          placement: 'live_wallpaper_unlock',
        );
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadRewardedAd();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(RewardedAdShowResult.failedToShow);
        }
      },
    );

    try {
      AppOpenManager.instance.suppressNextResume();
      _isShowingFullScreenAd = true;
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint(
            'AdService: Reward earned: ${reward.amount} ${reward.type}',
          );
          earnedReward = true;
        },
      );
    } catch (error) {
      _isShowingFullScreenAd = false;
      debugPrint('AdService: Rewarded show threw: $error');
      ad.dispose();
      loadRewardedAd();
      if (!showCompleter.isCompleted) {
        showCompleter.complete(RewardedAdShowResult.failedToShow);
      }
    }

    return showCompleter.future;
  }

  static Future<bool> loadAppOpenAd() {
    return AppOpenManager.instance.loadAd();
  }

  static Future<AppOpenAdShowResult> showAppOpenAdAndWait({
    Duration loadTimeout = const Duration(seconds: 8),
    bool respectMinInterval = false,
  }) async {
    if (_isShowingFullScreenAd) {
      debugPrint('AdService: Skipping app open while another ad is showing.');
      return AppOpenAdShowResult.notReady;
    }
    return AppOpenManager.instance.showAdIfAvailable(
      loadTimeout: loadTimeout,
      respectMinInterval: respectMinInterval,
      placement: 'app_open',
    );
  }

  static void dispose() {
    debugPrint('AdService: Disposing loaded ads.');
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    AppOpenManager.instance.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _interstitialLoadCompleter = null;
    _rewardedLoadCompleter = null;
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.collapsible = false,
    this.horizontalPadding = 0,
    this.mediumRectangle = false,
  });

  final bool collapsible;
  final double horizontalPadding;
  final bool mediumRectangle;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with AutomaticKeepAliveClientMixin<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int? _loadedWidth;
  bool _didFallbackFromCollapsible = false;
  String _currentFormat = 'banner';

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadForCurrentWidth();
  }

  void _loadForCurrentWidth() {
    final int width =
    (MediaQuery.sizeOf(context).width - widget.horizontalPadding)
        .truncate();
    if (_loadedWidth != width) {
      _loadedWidth = width;
      _loadBannerAd(width);
    }
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsible == widget.collapsible &&
        oldWidget.mediumRectangle == widget.mediumRectangle &&
        oldWidget.horizontalPadding == widget.horizontalPadding) {
      return;
    }
    _loadedWidth = null;
    _loadForCurrentWidth();
  }

  Future<void> _loadBannerAd(int width) async {
    _bannerAd?.dispose();
    _bannerAd = null;
    _didFallbackFromCollapsible = false;
    if (mounted) {
      setState(() => _isAdLoaded = false);
    }

    final bool shouldRequestCollapsible =
        !widget.mediumRectangle &&
            widget.collapsible &&
            ConfigManager.config.enableCollapsibleBanner;
    _currentFormat = widget.mediumRectangle
        ? 'banner'
        : shouldRequestCollapsible
        ? 'banner_collapsible'
        : 'banner';
    final BannerAd? bannerAd = await (widget.mediumRectangle
        ? AdService.loadMediumRectangleBannerAd(listener: _bannerAdListener())
        : shouldRequestCollapsible
        ? AdService.loadCollapsibleBannerAd(
      width: width,
      placement: ConfigManager.config.collapsibleBannerPosition,
      listener: _bannerAdListener(),
    )
        : AdService.loadAnchoredBannerAd(
      width: width,
      listener: _bannerAdListener(),
    ));

    if (bannerAd == null) {
      return;
    }
    if (!mounted) {
      bannerAd.dispose();
      return;
    }
  }

  BannerAdListener _bannerAdListener() {
    return BannerAdListener(
      onAdLoaded: (Ad ad) {
        final BannerAd bannerAd = ad as BannerAd;
        AdEventLogger.loaded(_currentFormat, placement: _bannerPlacement);
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() {
          _bannerAd = bannerAd;
          _isAdLoaded = true;
        });
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        AdEventLogger.failed(
          _currentFormat,
          error,
          placement: _bannerPlacement,
        );
        ad.dispose();
        if (widget.collapsible &&
            ConfigManager.config.enableCollapsibleBanner &&
            !_didFallbackFromCollapsible &&
            _loadedWidth != null) {
          _didFallbackFromCollapsible = true;
          _currentFormat = 'banner';
          AdService.loadAnchoredBannerAd(
            width: _loadedWidth!,
            listener: _bannerAdListener(),
          );
          return;
        }
        if (mounted) {
          setState(() => _isAdLoaded = false);
        }
      },
      onAdImpression: (Ad ad) {
        AdEventLogger.impression(_currentFormat, placement: _bannerPlacement);
      },
    );
  }

  String get _bannerPlacement {
    if (widget.mediumRectangle) {
      return 'grid_medium_rectangle';
    }
    if (widget.collapsible) {
      return ConfigManager.config.collapsibleBannerPosition;
    }
    return 'anchored';
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.mediumRectangle
          ? double.infinity
          : _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}