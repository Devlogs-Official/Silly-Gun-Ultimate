import 'dart:io';
import 'package:flutter/foundation.dart';
import 'config/config_manager.dart';

class AdIds {
  AdIds._();

  static const String _androidTestNativeId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _androidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _androidTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _androidTestAppOpenId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _androidTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _iosTestNativeId =
      'ca-app-pub-3940256099942544/3986624511';
  static const String _iosTestInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosTestRewardedId =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _iosTestAppOpenId =
      'ca-app-pub-3940256099942544/5575463023';
  static const String _iosTestBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static String get nativeId {
    if (Platform.isAndroid || Platform.isIOS) {
      return _withTestFallback(
        ConfigManager.config.nativeId,
        _androidTestNativeId,
        _iosTestNativeId,
      );
    }
    return '';
  }

  static String get collapsibleBannerId {
    if (Platform.isAndroid || Platform.isIOS) {
      return _withTestFallback(
        ConfigManager.config.collapsibleBannerId,
        _androidTestBannerId,
        _iosTestBannerId,
      );
    }
    return '';
  }

  static String get interstitialId {
    if (Platform.isAndroid || Platform.isIOS) {
      return _withTestFallback(
        ConfigManager.config.interstitialId,
        _androidTestInterstitialId,
        _iosTestInterstitialId,
      );
    }
    return '';
  }

  static String get appOpenId {
    if (Platform.isAndroid || Platform.isIOS) {
      return _withTestFallback(
        ConfigManager.config.appOpenId,
        _androidTestAppOpenId,
        _iosTestAppOpenId,
      );
    }
    return '';
  }

  static String get rewardedId {
    if (Platform.isAndroid || Platform.isIOS) {
      return _withTestFallback(
        ConfigManager.config.rewardedId,
        _androidTestRewardedId,
        _iosTestRewardedId,
      );
    }
    return '';
  }

  static String _withTestFallback(
    String configuredId,
    String androidTestId,
    String iosTestId,
  ) {
    if (configuredId.trim().isNotEmpty) {
      return configuredId.trim();
    }
    if (kReleaseMode) {
      return '';
    }
    return Platform.isIOS ? iosTestId : androidTestId;
  }
}
