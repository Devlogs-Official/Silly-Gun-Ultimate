import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../app_logger.dart';
import 'app_config.dart';

class ConfigManager extends ChangeNotifier {
  ConfigManager._();

  static final ConfigManager instance = ConfigManager._();

  AppConfig _config = AppConfig.defaults;

  static AppConfig get config => instance._config;

  AppConfig get current => _config;

  Future<AppConfig> fetchAndActivateRemoteConfig() async {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setDefaults(AppConfig.remoteDefaults);
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kReleaseMode
            ? const Duration(hours: 1)
            : Duration.zero,
      ),
    );

    try {
      await remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Remote Config fetch and activate failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final AppConfig config = AppConfig.fromRemoteConfig(remoteConfig);
    update(config);
    return config;
  }

  void update(AppConfig config) {
    _config = config;
    notifyListeners();
  }
}
