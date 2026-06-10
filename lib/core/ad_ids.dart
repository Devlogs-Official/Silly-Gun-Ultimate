import 'dart:io';
import 'config/config_manager.dart';

class AdIds {
  AdIds._();

  static String get bannerId {
    if (Platform.isAndroid || Platform.isIOS) {
      return ConfigManager.config.bannerId;
    }
    return '';
  }

  static String get collapsibleBannerId {
    if (Platform.isAndroid || Platform.isIOS) {
      return ConfigManager.config.collapsibleBannerId;
    }
    return '';
  }

  static String get interstitialId {
    if (Platform.isAndroid || Platform.isIOS) {
      return ConfigManager.config.interstitialId;
    }
    return '';
  }

  static String get appOpenId {
    if (Platform.isAndroid || Platform.isIOS) {
      return ConfigManager.config.appOpenId;
    }
    return '';
  }

  static String get rewardedId {
    if (Platform.isAndroid || Platform.isIOS) {
      return ConfigManager.config.rewardedId;
    }
    return '';
  }
}