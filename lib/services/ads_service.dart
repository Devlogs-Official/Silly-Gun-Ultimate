import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ad_ids.dart';
import '../core/ads/consent_manager.dart';
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

  static bool get _canShowAds =>
      ConfigManager.config.showAds && ConsentManager.canRequestAdsNow;
  static bool get _canShowInterstitialAds =>
      _canShowAds && ConfigManager.config.showInterstitialAds;
  static bool get _canShowRewardedAds =>
      _canShowAds && ConfigManager.config.showRewardedAds;
  static bool get _canShowNativeAds =>
      _canShowAds &&
      ConfigManager.config.showNativeAds &&
      ConfigManager.config.enableNativeAds;
  static bool get _canShowCollapsibleBannerAds =>
      _canShowAds && ConfigManager.config.enableCollapsibleBanner;

  static bool get isShowingFullScreenAd =>
      _isShowingFullScreenAd || AppOpenManager.instance.isShowingAd;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
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

  static Future<NativeAd?> loadNativeAd({
    String placement = 'native',
    NativeAdListener? listener,
  }) async {
    if (!_canShowNativeAds || AdIds.nativeId.isEmpty) {
      debugPrint('AdService: Native ads disabled.');
      return null;
    }

    final Completer<NativeAd?> loadCompleter = Completer<NativeAd?>();
    late final NativeAd nativeAd;
    nativeAd = NativeAd(
      adUnitId: AdIds.nativeId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
      listener:
          listener ??
          NativeAdListener(
            onAdLoaded: (Ad ad) {
              AdEventLogger.loaded('native', placement: placement);
              if (!loadCompleter.isCompleted) {
                loadCompleter.complete(ad as NativeAd);
              }
            },
            onAdFailedToLoad: (Ad ad, LoadAdError error) {
              AdEventLogger.failed('native', error, placement: placement);
              ad.dispose();
              if (!loadCompleter.isCompleted) {
                loadCompleter.complete(null);
              }
            },
            onAdImpression: (Ad ad) {
              AdEventLogger.impression('native', placement: placement);
            },
          ),
    );

    AdEventLogger.requested('native', placement: placement);
    await nativeAd.load();
    return loadCompleter.future;
  }

  static void disposeNativeAd(NativeAd? ad) {
    ad?.dispose();
  }

  static Widget getNativeAdWidget(NativeAd ad) {
    return AdWidget(ad: ad);
  }

  static Future<BannerAd?> loadCollapsibleBannerAd({
    required int width,
    String placement = 'bottom',
    BannerAdListener? listener,
  }) async {
    if (!_canShowCollapsibleBannerAds || AdIds.collapsibleBannerId.isEmpty) {
      debugPrint('AdService: Collapsible banner ads disabled.');
      return null;
    }

    final AnchoredAdaptiveBannerAdSize? size =
        // ignore: deprecated_member_use
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null) {
      debugPrint(
        'AdService: Unable to resolve collapsible banner adaptive size.',
      );
      return null;
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: AdIds.collapsibleBannerId,
      size: size,
      request: AdRequest(extras: <String, String>{'collapsible': placement}),
      listener: listener ?? const BannerAdListener(),
    );

    AdEventLogger.requested('banner_collapsible', placement: placement);
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

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    this.placement = 'native',
    this.height = 320,
  });

  final String placement;
  final double height;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  @override
  void didUpdateWidget(covariant NativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) {
      _loadNativeAd();
    }
  }

  Future<void> _loadNativeAd() async {
    AdService.disposeNativeAd(_nativeAd);
    _nativeAd = null;
    if (mounted) {
      setState(() => _isAdLoaded = false);
    }

    final NativeAd? nativeAd = await AdService.loadNativeAd(
      placement: widget.placement,
    );
    if (!mounted) {
      AdService.disposeNativeAd(nativeAd);
      return;
    }
    if (nativeAd == null) {
      return;
    }
    setState(() {
      _nativeAd = nativeAd;
      _isAdLoaded = true;
    });
  }

  @override
  void dispose() {
    AdService.disposeNativeAd(_nativeAd);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AdService.getNativeAdWidget(_nativeAd!),
    );
  }
}

class CollapsibleAdWidget extends StatefulWidget {
  const CollapsibleAdWidget({super.key, this.horizontalPadding = 0});

  final double horizontalPadding;

  @override
  State<CollapsibleAdWidget> createState() => _CollapsibleAdWidgetState();
}

class _CollapsibleAdWidgetState extends State<CollapsibleAdWidget>
    with AutomaticKeepAliveClientMixin<CollapsibleAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int? _loadedWidth;

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
      _loadCollapsibleBannerAd(width);
    }
  }

  @override
  void didUpdateWidget(covariant CollapsibleAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontalPadding == widget.horizontalPadding) {
      return;
    }
    _loadedWidth = null;
    _loadForCurrentWidth();
  }

  Future<void> _loadCollapsibleBannerAd(int width) async {
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) {
      setState(() => _isAdLoaded = false);
    }

    final BannerAd? bannerAd = await AdService.loadCollapsibleBannerAd(
      width: width,
      placement: ConfigManager.config.collapsibleBannerPosition,
      listener: _bannerAdListener(),
    );

    if (bannerAd == null) {
      return;
    }
    if (!mounted) {
      bannerAd.dispose();
    }
  }

  BannerAdListener _bannerAdListener() {
    return BannerAdListener(
      onAdLoaded: (Ad ad) {
        final BannerAd bannerAd = ad as BannerAd;
        AdEventLogger.loaded(
          'banner_collapsible',
          placement: ConfigManager.config.collapsibleBannerPosition,
        );
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
          'banner_collapsible',
          error,
          placement: ConfigManager.config.collapsibleBannerPosition,
        );
        ad.dispose();
        if (mounted) {
          setState(() => _isAdLoaded = false);
        }
      },
      onAdImpression: (Ad ad) {
        AdEventLogger.impression(
          'banner_collapsible',
          placement: ConfigManager.config.collapsibleBannerPosition,
        );
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
    super.build(context);
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
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
