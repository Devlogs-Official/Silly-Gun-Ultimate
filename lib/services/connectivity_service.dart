import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/app_logger.dart';

enum InternetTransport { none, wifi, mobile, other }

/// Tracks the OS-reported connectivity transport (WiFi / mobile / none).
///
/// We deliberately *do not* run reachability pings (e.g. via
/// `internet_connection_checker`) to gate UI. Those produce false negatives on
/// mobile networks, captive-portal setups, ad-blocking DNS, and restricted
/// regions — which then surface as misleading "no internet" snackbars even
/// when the user clearly has a working connection. Instead we treat any active
/// transport as "has internet" and let real API calls fail with their own
/// error if the network turns out to be broken — `WallpaperService` already
/// translates `SocketException` / timeout into a user-facing message.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _hasInternet = false;
  InternetTransport _transport = InternetTransport.none;
  bool _isInitialized = false;

  bool get hasInternet => _hasInternet;
  bool get isInitialized => _isInitialized;
  bool get isOffline => !_hasInternet;
  InternetTransport get transport => _transport;
  bool get isWifi => _transport == InternetTransport.wifi;
  bool get isMobile => _transport == InternetTransport.mobile;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _applyState(results, notify: false);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_applyState);

    _isInitialized = true;
    _notifySafely();
  }

  Future<bool> refresh() async {
    final results = await _connectivity.checkConnectivity();
    _applyState(results);
    return _hasInternet;
  }

  void _applyState(List<ConnectivityResult> results, {bool notify = true}) {
    final nextTransport = _transportFrom(results);
    final nextHasInternet = nextTransport != InternetTransport.none;

    if (_transport == nextTransport &&
        _hasInternet == nextHasInternet &&
        _isInitialized) {
      return;
    }

    _transport = nextTransport;
    _hasInternet = nextHasInternet;
    AppLogger.connectivity(
      'Connectivity changed',
      data: {'transport': _transport.name, 'internet': _hasInternet},
    );

    if (notify) _notifySafely();
  }

  InternetTransport _transportFrom(List<ConnectivityResult> results) {
    if (results.isEmpty) return InternetTransport.none;
    if (results.contains(ConnectivityResult.none)) return InternetTransport.none;
    if (results.contains(ConnectivityResult.wifi)) return InternetTransport.wifi;
    if (results.contains(ConnectivityResult.mobile)) {
      return InternetTransport.mobile;
    }
    if (results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn) ||
        results.contains(ConnectivityResult.bluetooth)) {
      return InternetTransport.other;
    }
    return InternetTransport.none;
  }

  void _notifySafely() {
    if (hasListeners) notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
