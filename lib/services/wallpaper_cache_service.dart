import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_exceptions.dart';
import '../core/app_logger.dart';
import '../models/wallpaper_model.dart';

class WallpaperCacheService {
  static const String _boxName = 'wallpapers_cache';
  static const String _legacyItemsKey = 'items';
  static const String _legacyCurrentPageKey = 'current_page';
  static const String _legacyTotalPagesKey = 'total_pages';
  static const String _lastUpdatedKey = 'wallpapers_last_updated';

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox<dynamic>(_boxName);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Cache initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CacheException('Unable to initialize offline cache.');
    }
  }

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  List<WallpaperModel> readWallpapers({bool isLive = true}) {
    try {
      final rawItems = _box.get(_itemsKeyFor(isLive)) ??
          (isLive ? _box.get(_legacyItemsKey) : null);
      if (rawItems is! List) return [];

      return rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(WallpaperModel.fromJson)
          .toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Reading cached wallpaper metadata failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CacheException('Unable to read cached wallpapers.');
    }
  }

  int readCurrentPage({bool isLive = true}) => _readInt(
        _currentPageKeyFor(isLive),
        fallback: isLive ? _readInt(_legacyCurrentPageKey, fallback: 0) : 0,
      );

  int readTotalPages({bool isLive = true}) => _readInt(
        _totalPagesKeyFor(isLive),
        fallback: isLive ? _readInt(_legacyTotalPagesKey, fallback: 1) : 1,
      );

  Future<void> saveWallpapers({
    required List<WallpaperModel> wallpapers,
    required int currentPage,
    required int totalPages,
    bool isLive = true,
  }) async {
    try {
      await _box.put(
        _itemsKeyFor(isLive),
        wallpapers.map((wallpaper) => wallpaper.toJson()).toList(),
      );
      await _box.put(_currentPageKeyFor(isLive), currentPage);
      await _box.put(_totalPagesKeyFor(isLive), totalPages);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _lastUpdatedKey,
        DateTime.now().toIso8601String(),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Saving cached wallpapers failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const CacheException('Unable to update offline cache.');
    }
  }

  Future<void> clear() async {
    await _box.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastUpdatedKey);
  }

  int _readInt(String key, {required int fallback}) {
    final value = _box.get(key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _itemsKeyFor(bool isLive) =>
      isLive ? 'items_live' : 'items_static';

  static String _currentPageKeyFor(bool isLive) =>
      isLive ? 'current_page_live' : 'current_page_static';

  static String _totalPagesKeyFor(bool isLive) =>
      isLive ? 'total_pages_live' : 'total_pages_static';
}
