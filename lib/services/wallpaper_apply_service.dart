import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import '../core/app_logger.dart';

class WallpaperApplyException implements Exception {
  const WallpaperApplyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WallpaperApplyService {
  WallpaperApplyService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> applyLiveWallpaper({
    required String videoUrl,
    required String fileName,
  }) async {
    if (!Platform.isAndroid) {
      throw const WallpaperApplyException(
        'Live wallpaper applying is supported on Android only.',
      );
    }

    final file = await _downloadVideo(videoUrl: videoUrl, fileName: fileName);

    try {
      final message = await WallpaperManagerPlus().setLiveWallpaper(file);
      return message ?? 'Live wallpaper picker opened.';
    } catch (error, stackTrace) {
      AppLogger.error(
        'Opening live wallpaper picker failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const WallpaperApplyException(
        'Could not open the live wallpaper picker.',
      );
    }
  }

  Future<String> applyStaticWallpaper({
    required String imageUrl,
    required String fileName,
    int location = WallpaperManagerPlus.bothScreens,
  }) async {
    if (!Platform.isAndroid) {
      throw const WallpaperApplyException(
        'Wallpaper applying is supported on Android only.',
      );
    }

    final file = await _downloadImage(imageUrl: imageUrl, fileName: fileName);

    try {
      await WallpaperManagerPlus().setWallpaper(file, location);

      return 'Wallpaper applied successfully.';
    } catch (error, stackTrace) {
      AppLogger.error(
        'Applying static wallpaper failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw const WallpaperApplyException('Could not apply wallpaper.');
    }
  }

  Future<File> _downloadImage({
    required String imageUrl,
    required String fileName,
  }) async {
    final uri = Uri.tryParse(imageUrl);

    if (uri == null || !_isHttpUri(uri)) {
      throw const WallpaperApplyException('Invalid wallpaper image URL.');
    }

    try {
      final directory = await getTemporaryDirectory();

      final safeName = fileName.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');

      final file = File('${directory.path}/$safeName.jpg');

      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const WallpaperApplyException(
          'Could not download wallpaper image.',
        );
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);

      return file;
    } on TimeoutException {
      throw const WallpaperApplyException('Image download timed out.');
    } on SocketException {
      throw const WallpaperApplyException(
        'No internet connection. Please try again.',
      );
    } on http.ClientException {
      throw const WallpaperApplyException(
        'Network error while downloading wallpaper.',
      );
    } on WallpaperApplyException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Preparing static wallpaper failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw const WallpaperApplyException('Unable to prepare wallpaper.');
    }
  }

  Future<File> _downloadVideo({
    required String videoUrl,
    required String fileName,
  }) async {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null || !_isHttpUri(uri)) {
      throw const WallpaperApplyException('Invalid wallpaper video URL.');
    }

    try {
      final directory = await getTemporaryDirectory();
      final safeName = fileName.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
      final file = File('${directory.path}/$safeName.mp4');

      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const WallpaperApplyException(
          'Could not download wallpaper video.',
        );
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file;
    } on TimeoutException {
      throw const WallpaperApplyException('Video download timed out.');
    } on SocketException {
      throw const WallpaperApplyException(
        'No internet connection. Please try again.',
      );
    } on http.ClientException {
      throw const WallpaperApplyException(
        'Network error while downloading wallpaper.',
      );
    } on WallpaperApplyException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Preparing live wallpaper failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const WallpaperApplyException('Unable to prepare live wallpaper.');
    }
  }

  bool _isHttpUri(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

  void dispose() => _client.close();
}
