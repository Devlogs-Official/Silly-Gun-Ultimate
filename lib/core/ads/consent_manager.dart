import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app_logger.dart';

class ConsentManager {
  ConsentManager._();

  static const bool enableDebugConsentTesting = kDebugMode;
  static const DebugGeography debugGeography = DebugGeography.debugGeographyEea;
  static bool _canRequestAds = false;

  static bool get canRequestAdsNow => _canRequestAds;

  static Future<void> initializeConsent() async {
    final params = ConsentRequestParameters(
      consentDebugSettings: enableDebugConsentTesting
          ? ConsentDebugSettings(debugGeography: debugGeography)
          : null,
    );

    try {
      _log('Requesting consent info update.');
      await _requestConsentInfoUpdate(params);
      await _logConsentState('After consent info update');

      final formAvailable = await ConsentInformation.instance
          .isConsentFormAvailable();
      _log('Form available: $formAvailable');

      if (!formAvailable) {
        _log('No consent form available for this user.');
        return;
      }

      _log('Loading and showing consent form if required.');
      await _loadAndShowConsentFormIfRequired();
      await _logConsentState('After consent form dismissal');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Consent flow failed',
        error: error,
        stackTrace: stackTrace,
      );
      _log('Error: $error');
    } finally {
      await canRequestAds();
    }
  }

  static Future<bool> canRequestAds() async {
    try {
      final canRequestAds = await ConsentInformation.instance.canRequestAds();
      _canRequestAds = canRequestAds;
      _log('Can request ads: $canRequestAds');
      return canRequestAds;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unable to read consent canRequestAds',
        error: error,
        stackTrace: stackTrace,
      );
      _log('Can request ads error: $error');
      _canRequestAds = false;
      return false;
    }
  }

  static Future<void> resetConsentForTesting() async {
    if (!kDebugMode) {
      _log('Consent reset ignored outside debug builds.');
      return;
    }

    try {
      await ConsentInformation.instance.reset();
      _canRequestAds = false;
      _log('Consent reset for testing.');
      await _logConsentState('After consent reset');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Consent reset failed',
        error: error,
        stackTrace: stackTrace,
      );
      _log('Consent reset error: $error');
    }
  }

  static Future<void> _requestConsentInfoUpdate(
    ConsentRequestParameters params,
  ) {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        _log('Consent info update succeeded.');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (formError) {
        _logFormError('Consent info update failed', formError);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    return completer.future;
  }

  static Future<void> _loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      if (formError == null) {
        _log('Form shown/dismissed successfully, or not required.');
      } else {
        _logFormError('Form dismissed with error', formError);
      }

      if (!completer.isCompleted) {
        completer.complete();
      }
    }).catchError((Object error, StackTrace stackTrace) {
      AppLogger.error(
        'Consent form load/show failed',
        error: error,
        stackTrace: stackTrace,
      );
      _log('Form load/show error: $error');
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    return completer.future;
  }

  static Future<void> _logConsentState(String label) async {
    if (!kDebugMode) {
      return;
    }

    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      final canRequestAds = await ConsentInformation.instance.canRequestAds();
      final formAvailable = await ConsentInformation.instance
          .isConsentFormAvailable();

      _log(
        '$label: status=${status.name}, '
        'canRequestAds=$canRequestAds, '
        'formAvailable=$formAvailable',
      );
    } catch (error) {
      _log('$label: state logging failed: $error');
    }
  }

  static void _logFormError(String prefix, FormError formError) {
    _log(
      '$prefix: code=${formError.errorCode}, '
      'message=${formError.message}',
    );
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('ConsentManager: $message');
    }
  }
}
