class WallpapersMeta {
  const WallpapersMeta({
    required this.type,
    required this.isLive,
  });

  final String type;
  final bool isLive;

  factory WallpapersMeta.fromJson(Map<String, dynamic> json) {
    return WallpapersMeta(
      type: (json['type'] as String?)?.trim() ?? '',
      isLive: _parseBool(json['is_live']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'is_live': isLive ? 1 : 0,
    };
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    final raw = value?.toString().toLowerCase().trim();
    return raw == '1' || raw == 'true';
  }
}
