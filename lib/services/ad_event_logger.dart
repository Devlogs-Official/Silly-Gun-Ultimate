import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdEventType { requested, loaded, failed, shown, dismissed, impression }

class AdEventLogger {
  AdEventLogger._();

  static final Map<String, int> _requests = <String, int>{};
  static final Map<String, int> _loads = <String, int>{};
  static final Map<String, int> _impressions = <String, int>{};
  static final Map<String, int> _shows = <String, int>{};

  static void requested(String format, {String? placement}) {
    _increment(_requests, format);
    _log(AdEventType.requested, format, placement: placement);
  }

  static void loaded(String format, {String? placement}) {
    _increment(_loads, format);
    _log(AdEventType.loaded, format, placement: placement);
  }

  static void failed(String format, LoadAdError error, {String? placement}) {
    _log(
      AdEventType.failed,
      format,
      placement: placement,
      detail:
      'code=${error.code}, domain=${error.domain}, '
          'message=${error.message}',
    );
  }

  static void failedToShow(String format, AdError error, {String? placement}) {
    _log(
      AdEventType.failed,
      format,
      placement: placement,
      detail:
      'showCode=${error.code}, domain=${error.domain}, '
          'message=${error.message}',
    );
  }

  static void shown(String format, {String? placement}) {
    _increment(_shows, format);
    _log(AdEventType.shown, format, placement: placement);
  }

  static void dismissed(String format, {String? placement}) {
    _log(AdEventType.dismissed, format, placement: placement);
  }

  static void impression(String format, {String? placement}) {
    _increment(_impressions, format);
    _log(AdEventType.impression, format, placement: placement);
  }

  static Map<String, Map<String, num>> snapshot() {
    final Set<String> formats = <String>{
      ..._requests.keys,
      ..._loads.keys,
      ..._impressions.keys,
      ..._shows.keys,
    };
    return <String, Map<String, num>>{
      for (final String format in formats)
        format: <String, num>{
          'requests': _requests[format] ?? 0,
          'matchedRequests': _loads[format] ?? 0,
          'impressions': _impressions[format] ?? 0,
          'shows': _shows[format] ?? 0,
          'showRate': _rate(_shows[format], _loads[format]),
          'matchRate': _rate(_loads[format], _requests[format]),
        },
    };
  }

  static void _increment(Map<String, int> values, String key) {
    values[key] = (values[key] ?? 0) + 1;
  }

  static double _rate(int? numerator, int? denominator) {
    final int bottom = denominator ?? 0;
    if (bottom == 0) {
      return 0;
    }
    return ((numerator ?? 0) / bottom) * 100;
  }

  static void _log(
      AdEventType event,
      String format, {
        String? placement,
        String? detail,
      }) {
    final String placementPart = placement == null || placement.isEmpty
        ? ''
        : ' placement=$placement';
    final String detailPart = detail == null ? '' : ' $detail';
    debugPrint(
      'AdMetrics: ${event.name.toUpperCase()} format=$format'
          '$placementPart$detailPart',
    );
  }
}