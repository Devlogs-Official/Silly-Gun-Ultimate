import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:silly_gun_ultimate/core/app_constants.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import '../../core/app_logger.dart';
import '../../models/wallpaper_model.dart';
import '../../services/wallpaper_apply_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/bottom_action_buttons.dart';
import '../../widgets/video_loader.dart';

class StaticFullScreenPreview extends StatefulWidget {
  const StaticFullScreenPreview({super.key, required this.wallpaper});

  final WallpaperModel wallpaper;

  @override
  State<StaticFullScreenPreview> createState() =>
      _StaticFullScreenPreviewState();
}

class _StaticFullScreenPreviewState extends State<StaticFullScreenPreview> {
  final WallpaperApplyService _applyService = WallpaperApplyService();
  bool _isApplying = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _shareWallpaper() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Download video to a temp file
      final response = await http.get(Uri.parse(widget.wallpaper.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${widget.wallpaper.name.replaceAll(RegExp(r'[^\w]'), '_')}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: 'image/jpeg')],
          text: AppConstants.shareMessage,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Share failed', error: error, stackTrace: stackTrace);
      if (!mounted) return;
      AppSnackbar.error('Unable to share wallpaper. Please try again.');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _applyWallpaper(int location) async {
    if (_isApplying) return;

    setState(() => _isApplying = true);
    _showApplyingDialog();

    try {
      final message = await _applyService.applyStaticWallpaper(
        imageUrl: widget.wallpaper.imageUrl,
        fileName: widget.wallpaper.name,
        location: location,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      AppSnackbar.success(message);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Apply wallpaper failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      AppSnackbar.error(
        error is WallpaperApplyException
            ? error.message
            : 'Unable to apply wallpaper.',
      );
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  Future<void> _showWallpaperOptions() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home Screen'),
                onTap: () {
                  Navigator.pop(context, WallpaperManagerPlus.homeScreen);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Lock Screen'),
                onTap: () {
                  Navigator.pop(context, WallpaperManagerPlus.lockScreen);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Both Screens'),
                onTap: () {
                  Navigator.pop(context, WallpaperManagerPlus.bothScreens);
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      _applyWallpaper(result);
    }
  }

  void _showApplyingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xEE11151D),
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _applyService.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.wallpaper.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,

              placeholder: (context, url) => const VideoLoader(borderRadius: 0),

              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 40),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              left: 14,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.42),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionButtons(
        isApplying: _isApplying,
        onShare: () {
          if (!_isSharing) {
            _shareWallpaper();
          }
        },
        onApply: _showWallpaperOptions,
      ),
    );
  }
}
