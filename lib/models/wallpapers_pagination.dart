class WallpapersPagination {
  const WallpapersPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;

  factory WallpapersPagination.fromJson(Map<String, dynamic> json) {
    return WallpapersPagination(
      currentPage: _parseInt(json['current_page'], fallback: 1),
      pageSize: _parseInt(json['page_size'], fallback: 20),
      totalRecords: _parseInt(json['total_records']),
      totalPages: _parseInt(json['total_pages'], fallback: 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'page_size': pageSize,
      'total_records': totalRecords,
      'total_pages': totalPages,
    };
  }

  static int _parseInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
