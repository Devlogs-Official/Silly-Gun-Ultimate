import 'wallpaper_model.dart';
import 'wallpapers_meta.dart';
import 'wallpapers_pagination.dart';

class WallpapersResponse {
  const WallpapersResponse({
    required this.status,
    required this.message,
    required this.meta,
    required this.pagination,
    required this.data,
  });

  final bool status;
  final String message;
  final WallpapersMeta meta;
  final WallpapersPagination pagination;
  final List<WallpaperModel> data;

  factory WallpapersResponse.fromJson(Map<String, dynamic> json) {
    final metaMap =
        (json['meta'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final paginationMap =
        (json['pagination'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final rawData = json['data'];

    return WallpapersResponse(
      status: _parseBool(json['status']),
      message: (json['message'] as String?)?.trim() ?? '',
      meta: WallpapersMeta.fromJson(metaMap),
      pagination: WallpapersPagination.fromJson(paginationMap),
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (item) =>
                      WallpaperModel.fromJson(item.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const <WallpaperModel>[],
    );
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    final raw = value?.toString().toLowerCase().trim();
    return raw == '1' || raw == 'true' || raw == 'success';
  }
}
