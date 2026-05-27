import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/app_snackbar.dart';
import 'app_exceptions.dart';
import 'app_logger.dart';

class ErrorHandler {
  const ErrorHandler._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void initialize() {
    // Framework errors (image decode races, disposed controllers during
    // PageView swipes, layout overflows, codec teardown callbacks, etc.) are
    // logged but NOT surfaced as snackbars — they're rarely actionable for
    // the end user and were generating false "something went wrong" toasts
    // during normal live-wallpaper navigation.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
  }

  static void handleZoneError(Object error, StackTrace stackTrace) {
    // Uncaught zone errors are logged for diagnostics. We deliberately do not
    // raise a generic snackbar from here — every real, user-actionable error
    // path already surfaces its own specific message (apply failed, share
    // failed, no internet, …) via `AppSnackbar` or the retry widgets.
    AppLogger.error(
      'Uncaught zone error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String messageFor(Object error) {
    if (error is AppException) return error.message;
    if (error is TimeoutException) {
      return 'The request timed out. Please try again.';
    }
    if (error is SocketException) {
      return 'No internet connection. Please try again.';
    }
    if (error is FormatException) {
      return 'We could not read the server response.';
    }
    return 'Something went wrong. Please try again.';
  }

  static void showError(Object error) {
    AppSnackbar.error(messageFor(error));
  }

  static Future<T?> guard<T>(
    Future<T> Function() action, {
    String? fallbackMessage,
    bool showSnackbar = true,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      AppLogger.error('Guarded action failed', error: error, stackTrace: stackTrace);
      if (showSnackbar) {
        AppSnackbar.error(fallbackMessage ?? messageFor(error));
      }
      return null;
    }
  }
}
