import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/app_exceptions.dart';
import '../core/app_logger.dart';
import '../models/wallpaper_model.dart';
import '../services/wallpaper_cache_service.dart';
import '../services/wallpaper_service.dart';

class WallpaperProvider extends ChangeNotifier {
  WallpaperProvider({
    WallpaperService? service,
    WallpaperCacheService? cacheService,
  })  : _service = service ?? WallpaperService(),
        _cacheService = cacheService ?? WallpaperCacheService();

  static const int _pageSize = 20;

  final WallpaperService _service;
  final WallpaperCacheService _cacheService;

  final Map<bool, List<WallpaperModel>> _wallpapersByType = {
    true: <WallpaperModel>[],
    false: <WallpaperModel>[],
  };
  final Map<bool, int> _currentPageByType = {true: 0, false: 0};
  final Map<bool, int> _totalPagesByType = {true: 1, false: 1};
  final Map<bool, bool> _isLoadingByType = {true: false, false: false};
  final Map<bool, bool> _isLoadingMoreByType = {true: false, false: false};
  final Map<bool, bool> _cacheRestoredByType = {true: false, false: false};
  final Map<bool, String?> _errorByType = {true: null, false: null};

  UnmodifiableListView<WallpaperModel> get wallpapers =>
      wallpapersFor(isLive: true);
  int get currentPage => currentPageFor(isLive: true);
  int get totalPages => totalPagesFor(isLive: true);
  bool get isLoading => isLoadingFor(isLive: true);
  bool get isLoadingMore => isLoadingMoreFor(isLive: true);
  bool get hasMore => hasMoreFor(isLive: true);
  String? get errorMessage => errorMessageFor(isLive: true);

  UnmodifiableListView<WallpaperModel> wallpapersFor({required bool isLive}) =>
      UnmodifiableListView(_itemsFor(isLive));
  int currentPageFor({required bool isLive}) => _currentPageByType[isLive] ?? 0;
  int totalPagesFor({required bool isLive}) => _totalPagesByType[isLive] ?? 1;
  bool isLoadingFor({required bool isLive}) =>
      _isLoadingByType[isLive] ?? false;
  bool isLoadingMoreFor({required bool isLive}) =>
      _isLoadingMoreByType[isLive] ?? false;
  bool hasMoreFor({required bool isLive}) =>
      currentPageFor(isLive: isLive) < totalPagesFor(isLive: isLive);
  String? errorMessageFor({required bool isLive}) => _errorByType[isLive];

  bool restoreCachedWallpapers({bool isLive = true}) {
    _restoreCacheIfNeeded(isLive: isLive, notify: false);
    return _itemsFor(isLive).isNotEmpty;
  }

  Future<void> fetchInitialWallpapers({
    bool forceRefresh = false,
    bool isLive = true,
  }) async {
    if (isLoadingFor(isLive: isLive) || isLoadingMoreFor(isLive: isLive)) {
      return;
    }
    if (_itemsFor(isLive).isNotEmpty && !forceRefresh) return;

    _restoreCacheIfNeeded(isLive: isLive);

    _isLoadingByType[isLive] = true;
    _errorByType[isLive] = null;
    _notifySafely();

    try {
      final page = await _service.fetchWallpapers(
        page: 1,
        pageSize: _pageSize,
        isLive: isLive,
      );
      _itemsFor(isLive)
        ..clear()
        ..addAll(page.wallpapers);
      _currentPageByType[isLive] = page.currentPage;
      _totalPagesByType[isLive] = page.totalPages;
      await _saveCache(isLive: isLive);
    } on AppException catch (error) {
      if (_itemsFor(isLive).isEmpty) {
        _errorByType[isLive] = error.message;
      }
      AppLogger.error('Initial wallpapers fetch failed', error: error);
    } catch (error, stackTrace) {
      if (_itemsFor(isLive).isEmpty) {
        _errorByType[isLive] = 'Unable to load wallpapers.';
      }
      AppLogger.error(
        'Unexpected initial wallpapers fetch failure',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoadingByType[isLive] = false;
      _notifySafely();
    }
  }

  Future<void> fetchMoreWallpapers({bool isLive = true}) async {
    if (isLoadingFor(isLive: isLive) ||
        isLoadingMoreFor(isLive: isLive) ||
        !hasMoreFor(isLive: isLive)) {
      return;
    }

    _isLoadingMoreByType[isLive] = true;
    _errorByType[isLive] = null;
    _notifySafely();

    try {
      final page = await _service.fetchWallpapers(
        page: currentPageFor(isLive: isLive) + 1,
        pageSize: _pageSize,
        isLive: isLive,
      );
      final existingIds = _itemsFor(isLive).map((wallpaper) => wallpaper.id).toSet();
      final newItems = page.wallpapers.where(
        (wallpaper) => existingIds.add(wallpaper.id),
      );

      _itemsFor(isLive).addAll(newItems);
      _currentPageByType[isLive] = page.currentPage;
      _totalPagesByType[isLive] = page.totalPages;
      await _saveCache(isLive: isLive);
    } on AppException catch (error) {
      _errorByType[isLive] = error.message;
      AppLogger.error('Pagination fetch failed', error: error);
    } catch (error, stackTrace) {
      _errorByType[isLive] = 'Unable to load more wallpapers.';
      AppLogger.error(
        'Unexpected pagination fetch failure',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoadingMoreByType[isLive] = false;
      _notifySafely();
    }
  }

  Future<void> refreshWallpapers({bool isLive = true}) async {
    _currentPageByType[isLive] = 0;
    _totalPagesByType[isLive] = 1;
    _errorByType[isLive] = null;
    await fetchInitialWallpapers(forceRefresh: true, isLive: isLive);
  }

  Future<void> clearCacheAndReset() async {
    try {
      await _cacheService.clear();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Clearing wallpaper cache failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    for (final isLive in [true, false]) {
      _itemsFor(isLive).clear();
      _currentPageByType[isLive] = 0;
      _totalPagesByType[isLive] = 1;
      _isLoadingByType[isLive] = false;
      _isLoadingMoreByType[isLive] = false;
      _cacheRestoredByType[isLive] = false;
      _errorByType[isLive] = null;
    }
    _notifySafely();
  }

  void _restoreCacheIfNeeded({required bool isLive, bool notify = true}) {
    if ((_cacheRestoredByType[isLive] ?? false) || _itemsFor(isLive).isNotEmpty) {
      return;
    }

    List<WallpaperModel> cachedWallpapers = const [];
    try {
      cachedWallpapers = _cacheService.readWallpapers(isLive: isLive);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Reading cached wallpapers failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (cachedWallpapers.isEmpty) {
      _cacheRestoredByType[isLive] = true;
      return;
    }

    _itemsFor(isLive)
      ..clear()
      ..addAll(cachedWallpapers);
    _currentPageByType[isLive] = _cacheService.readCurrentPage(isLive: isLive);
    _totalPagesByType[isLive] = _cacheService.readTotalPages(isLive: isLive);
    _cacheRestoredByType[isLive] = true;
    if (notify) _notifySafely();
  }

  Future<void> _saveCache({required bool isLive}) {
    return _cacheService.saveWallpapers(
      wallpapers: _itemsFor(isLive),
      currentPage: currentPageFor(isLive: isLive),
      totalPages: totalPagesFor(isLive: isLive),
      isLive: isLive,
    );
  }

  List<WallpaperModel> _itemsFor(bool isLive) =>
      _wallpapersByType[isLive] ?? <WallpaperModel>[];

  void _notifySafely() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
