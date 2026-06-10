import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_exceptions.dart';
import '../core/app_logger.dart';
import '../core/config/config_manager.dart';
import '../models/wallpaper_model.dart';
import '../models/wallpapers_response.dart';

class WallpaperPage {
  const WallpaperPage({
    required this.wallpapers,
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  final List<WallpaperModel> wallpapers;
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
}

class WallpaperService {
  WallpaperService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  Future<WallpaperPage> fetchWallpapers({
    required int page,
    int pageSize = 20,
    bool isLive = true,
  }) async {
    final String baseUrl = ConfigManager.config.apiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw const ApiException('Wallpaper service is not configured yet.');
    }

    final uri = Uri.parse("$baseUrl/get_silly_wallpapers.php").replace(
      queryParameters: {
        'is_live': isLive ? '1' : '0',
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );

    AppLogger.api('Fetching wallpapers', data: uri);

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final serverMessage = _messageFromBody(response.body);
        throw ApiException(
          serverMessage ??
              'Server error ${response.statusCode}. Please try again.',
          debugMessage: response.body,
        );
      }

      if (response.body.trim().isEmpty) {
        throw const ApiException('The server returned an empty response.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Invalid server response.');
      }

      if (!_isSuccessStatus(decoded['status'])) {
        throw ApiException(
          (decoded['message'] as String?)?.trim().isNotEmpty == true
              ? decoded['message'] as String
              : 'Unable to load wallpapers.',
        );
      }

      final responseModel = WallpapersResponse.fromJson(decoded);
      if (!responseModel.status) {
        throw ApiException(
          responseModel.message.isNotEmpty
              ? responseModel.message
              : 'Unable to load wallpapers.',
        );
      }

      final currentPage = responseModel.pagination.currentPage < 1
          ? page
          : responseModel.pagination.currentPage;
      final pageSizeValue = responseModel.pagination.pageSize < 1
          ? pageSize
          : responseModel.pagination.pageSize;
      final totalPages = responseModel.pagination.totalPages < currentPage
          ? currentPage
          : responseModel.pagination.totalPages;

      return WallpaperPage(
        wallpapers: responseModel.data
            .where(
              (wallpaper) =>
                  wallpaper.thumbnailUrl.isNotEmpty &&
                  wallpaper.imageUrl.isNotEmpty,
            )
            .toList(growable: false),
        currentPage: currentPage,
        pageSize: pageSizeValue,
        totalRecords: responseModel.pagination.totalRecords,
        totalPages: totalPages,
      );
    } on TimeoutException {
      throw const NetworkException(
        'The request timed out. Check your connection and try again.',
      );
    } on SocketException {
      throw const NetworkException('No internet connection. Please try again.');
    } on FormatException catch (error) {
      throw ApiException(
        'Could not read server response.',
        debugMessage: error.toString(),
      );
    } on http.ClientException catch (error) {
      throw NetworkException(
        'Network error. Check your connection and try again.',
        debugMessage: error.toString(),
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected API failure',
        error: error,
        stackTrace: stackTrace,
      );
      throw const ApiException(
        'Something went wrong while loading wallpapers.',
      );
    }
  }

  String? _messageFromBody(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = (decoded['message'] as String?)?.trim();
        if (message?.isNotEmpty == true) return message;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _isSuccessStatus(Object? value) {
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    final raw = value?.toString().toLowerCase().trim();
    return raw == '1' || raw == 'true' || raw == 'success';
  }

  void dispose() => _client.close();
}
