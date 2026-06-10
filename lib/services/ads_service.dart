import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ad_ids.dart';
import '../core/config/config_manager.dart';
import 'app_open_manager.dart';

enum InterstitialAdShowResult { shown, disabled, notReady, failedToShow }

enum AppOpenAdShowResult { shown, disabled, notReady, failedToShow }

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
  static AppOpenAd? _appOpenAd;
  static RewardedAd? _rewardedAd;
  static BannerAd? _preloadedBannerAd;
  static BannerAd? _preloadedCollapsibleBannerAd;
  static Future<InitializationStatus>? _mobileAdsInitialization;
  static Completer<bool>? _interstitialLoadCompleter;
  static Completer<bool>? _appOpenLoadCompleter;
  static Completer<bool>? _rewardedLoadCompleter;
  static int? _preloadedBannerWidth;
  static int? _preloadedCollapsibleBannerWidth;
  static String? _lastRewardedLoadError;
  static DateTime? _lastAppOpenShownAt;
  static bool _isShowingFullScreenAd = false;

  static bool get _canShowAds => ConfigManager.config.showAds;
  static bool get _canShowInterstitialAds =>
      _canShowAds && ConfigManager.config.showInterstitialAds;
  static bool get _canShowAppOpenAds =>
      _canShowAds && ConfigManager.config.showAppOpenAds;
  static bool get _canShowBannerAds =>
      _canShowAds && ConfigManager.config.showBannerAds;
  static bool get _canShowRewardedAds =>
      _canShowAds && ConfigManager.config.showRewardedAds;

  static bool get isShowingFullScreenAd => _isShowingFullScreenAd;
  static bool get isAppOpenAdAvailable => _appOpenAd != null;

  static Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    _mobileAdsInitialization ??= MobileAds.instance.initialize();
    await _mobileAdsInitialization;
    debugPrint('AdService: Mobile Ads initialized.');
  }

  static Future<bool> preloadSplashAds() async {
    await initialize();

    debugPrint('AdService: Preloading splash ads.');
    final Future<bool> appOpenLoad = loadAppOpenAd();
    unawaited(loadInterstitialAd());

    return appOpenLoad;
  }

  static Future<void> preloadBannerAds({required int width}) async {
    await initialize();
    if (!_canShowBannerAds || AdIds.bannerId.isEmpty) {
      debugPrint('AdService: Banner preload skipped.');
      return;
    }

    if (_preloadedBannerAd == null && _preloadedBannerWidth != width) {
      _preloadedBannerWidth = width;
      unawaited(
        loadAnchoredBannerAd(
          width: width,
          listener: BannerAdListener(
            onAdLoaded: (Ad ad) {
              _preloadedBannerAd = ad as BannerAd;
              debugPrint('AdService: Preloaded banner ad.');
            },
            onAdFailedToLoad: (Ad ad, LoadAdError error) {
              debugPrint(
                'AdService: Preloaded banner failed: ${error.message}',
              );
              ad.dispose();
              _preloadedBannerAd = null;
              _preloadedBannerWidth = null;
            },
          ),
        ),
      );
    }

    if (!ConfigManager.config.enableCollapsibleBanner ||
        _preloadedCollapsibleBannerAd != null ||
        _preloadedCollapsibleBannerWidth == width) {
      return;
    }

    _preloadedCollapsibleBannerWidth = width;
    unawaited(
      loadCollapsibleBannerAd(
        width: width,
        placement: ConfigManager.config.collapsibleBannerPosition,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            _preloadedCollapsibleBannerAd = ad as BannerAd;
            debugPrint('AdService: Preloaded collapsible banner ad.');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint(
              'AdService: Preloaded collapsible banner failed: ${error.message}',
            );
            ad.dispose();
            _preloadedCollapsibleBannerAd = null;
            _preloadedCollapsibleBannerWidth = null;
          },
        ),
      ),
    );
  }

  static BannerAd? takePreloadedBannerAd({required int width}) {
    if (_preloadedBannerWidth != width) {
      return null;
    }
    final BannerAd? bannerAd = _preloadedBannerAd;
    _preloadedBannerAd = null;
    _preloadedBannerWidth = null;
    return bannerAd;
  }

  static BannerAd? takePreloadedCollapsibleBannerAd({required int width}) {
    if (_preloadedCollapsibleBannerWidth != width) {
      return null;
    }
    final BannerAd? bannerAd = _preloadedCollapsibleBannerAd;
    _preloadedCollapsibleBannerAd = null;
    _preloadedCollapsibleBannerWidth = null;
    return bannerAd;
  }

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

    debugPrint('AdService: Loading interstitial ad.');
    final Completer<bool> loadCompleter = Completer<bool>();
    _interstitialLoadCompleter = loadCompleter;

    InterstitialAd.load(
      adUnitId: AdIds.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadCompleter = null;
          debugPrint('AdService: Interstitial ad loaded.');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint(
            'AdService: Interstitial failed to load: ${error.message}',
          );
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
        debugPrint('AdService: Interstitial ad showed.');
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        debugPrint('AdService: Interstitial ad dismissed.');
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadInterstitialAd();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(InterstitialAdShowResult.shown);
        }
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        debugPrint('AdService: Interstitial failed to show: ${error.message}');
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

    debugPrint(
      'AdService: Loading rewarded ad. '
      'adUnitId=${_safeAdUnitId(AdIds.rewardedId)}',
    );
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
          debugPrint('AdService: Rewarded ad loaded.');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _lastRewardedLoadError =
              'code=${error.code}, domain=${error.domain}, '
              'message=${error.message}';
          debugPrint(
            'AdService: Rewarded failed to load: $_lastRewardedLoadError',
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
    Duration loadTimeout = const Duration(seconds: 90),
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
        debugPrint('AdService: Rewarded ad showed.');
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        debugPrint('AdService: Rewarded ad dismissed.');
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
        debugPrint('AdService: Rewarded failed to show: ${error.message}');
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
    if (!_canShowAppOpenAds || AdIds.appOpenId.isEmpty) {
      debugPrint('AdService: App open ads disabled.');
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadCompleter = null;
      return Future<bool>.value(false);
    }
    if (_appOpenAd != null) {
      return Future<bool>.value(true);
    }
    if (_appOpenLoadCompleter != null) {
      return _appOpenLoadCompleter!.future;
    }

    debugPrint('AdService: Loading app open ad.');
    final Completer<bool> loadCompleter = Completer<bool>();
    _appOpenLoadCompleter = loadCompleter;

    AppOpenAd.load(
      adUnitId: AdIds.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          _appOpenLoadCompleter = null;
          debugPrint('AdService: App open ad loaded.');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdService: App open failed to load: ${error.message}');
          _appOpenAd = null;
          _appOpenLoadCompleter = null;
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(false);
          }
        },
      ),
    );

    return loadCompleter.future;
  }

  static Future<AppOpenAdShowResult> showAppOpenAdAndWait({
    Duration loadTimeout = const Duration(seconds: 8),
    bool respectMinInterval = false,
  }) async {
    if (!_canShowAppOpenAds || AdIds.appOpenId.isEmpty) {
      debugPrint('AdService: App open ads disabled.');
      return AppOpenAdShowResult.disabled;
    }
    if (_isShowingFullScreenAd) {
      debugPrint('AdService: Skipping app open while another ad is showing.');
      return AppOpenAdShowResult.notReady;
    }
    if (respectMinInterval && !_hasPassedAppOpenInterval()) {
      debugPrint('AdService: App open skipped by min interval.');
      return AppOpenAdShowResult.notReady;
    }

    if (_appOpenAd == null) {
      final bool loaded = await loadAppOpenAd().timeout(
        loadTimeout,
        onTimeout: () => false,
      );
      if (!loaded || _appOpenAd == null) {
        debugPrint('AdService: App open ad not ready.');
        return AppOpenAdShowResult.notReady;
      }
    }

    final AppOpenAd ad = _appOpenAd!;
    _appOpenAd = null;
    final Completer<AppOpenAdShowResult> showCompleter =
        Completer<AppOpenAdShowResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        debugPrint('AdService: App open ad showed.');
        _lastAppOpenShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        debugPrint('AdService: App open ad dismissed.');
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadAppOpenAd();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(AppOpenAdShowResult.shown);
        }
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        debugPrint('AdService: App open failed to show: ${error.message}');
        _isShowingFullScreenAd = false;
        ad.dispose();
        loadAppOpenAd();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(AppOpenAdShowResult.failedToShow);
        }
      },
    );

    try {
      _isShowingFullScreenAd = true;
      await ad.show();
    } catch (error) {
      _isShowingFullScreenAd = false;
      debugPrint('AdService: App open show threw: $error');
      ad.dispose();
      loadAppOpenAd();
      if (!showCompleter.isCompleted) {
        showCompleter.complete(AppOpenAdShowResult.failedToShow);
      }
    }

    return showCompleter.future;
  }

  static bool _hasPassedAppOpenInterval() {
    final DateTime? lastShown = _lastAppOpenShownAt;
    if (lastShown == null) {
      return true;
    }
    final int seconds = ConfigManager.config.appOpenMinIntervalSeconds;
    return DateTime.now().difference(lastShown) >= Duration(seconds: seconds);
  }

  static void dispose() {
    debugPrint('AdService: Disposing loaded ads.');
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
    _rewardedAd?.dispose();
    _preloadedBannerAd?.dispose();
    _preloadedCollapsibleBannerAd?.dispose();
    _interstitialAd = null;
    _appOpenAd = null;
    _rewardedAd = null;
    _preloadedBannerAd = null;
    _preloadedCollapsibleBannerAd = null;
    _preloadedBannerWidth = null;
    _preloadedCollapsibleBannerWidth = null;
    _interstitialLoadCompleter = null;
    _appOpenLoadCompleter = null;
    _rewardedLoadCompleter = null;
  }

  static String _safeAdUnitId(String adUnitId) {
    if (adUnitId.isEmpty) {
      return '<empty>';
    }
    final int visibleCount = adUnitId.length < 8 ? adUnitId.length : 8;
    return '...${adUnitId.substring(adUnitId.length - visibleCount)}';
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.collapsible = true,
    this.horizontalPadding = 0,
    this.mediumRectangle = false,
    this.onLoadStateChanged,
  });

  final bool collapsible;
  final double horizontalPadding;
  final bool mediumRectangle;
  final ValueChanged<bool>? onLoadStateChanged;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int? _loadedWidth;
  bool _didFallbackFromCollapsible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int width =
        (MediaQuery.sizeOf(context).width - widget.horizontalPadding)
            .truncate();
    if (_loadedWidth != width) {
      _loadedWidth = width;
      _loadBannerAd(width);
    }
  }

  Future<void> _loadBannerAd(int width) async {
    _bannerAd?.dispose();
    _bannerAd = null;
    _didFallbackFromCollapsible = false;
    widget.onLoadStateChanged?.call(false);
    if (mounted) {
      setState(() => _isAdLoaded = false);
    }

    final bool shouldRequestCollapsible =
        !widget.mediumRectangle &&
        widget.collapsible &&
        ConfigManager.config.enableCollapsibleBanner;
    final BannerAd? preloadedBannerAd = widget.mediumRectangle
        ? null
        : shouldRequestCollapsible
        ? AdService.takePreloadedCollapsibleBannerAd(width: width)
        : AdService.takePreloadedBannerAd(width: width);
    if (preloadedBannerAd != null) {
      if (!mounted) {
        preloadedBannerAd.dispose();
        return;
      }
      setState(() {
        _bannerAd = preloadedBannerAd;
        _isAdLoaded = true;
      });
      widget.onLoadStateChanged?.call(true);
      return;
    }

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
      widget.onLoadStateChanged?.call(false);
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
        debugPrint(
          'BannerAdWidget: Banner loaded. Collapsible: ${bannerAd.isCollapsible}',
        );
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() {
          _bannerAd = bannerAd;
          _isAdLoaded = true;
        });
        widget.onLoadStateChanged?.call(true);
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        debugPrint('BannerAdWidget: Banner failed: ${error.message}');
        ad.dispose();
        if (widget.collapsible &&
            ConfigManager.config.enableCollapsibleBanner &&
            !_didFallbackFromCollapsible &&
            _loadedWidth != null) {
          _didFallbackFromCollapsible = true;
          AdService.loadAnchoredBannerAd(
            width: _loadedWidth!,
            listener: _bannerAdListener(),
          );
          return;
        }
        if (mounted) {
          setState(() => _isAdLoaded = false);
        }
        widget.onLoadStateChanged?.call(false);
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
