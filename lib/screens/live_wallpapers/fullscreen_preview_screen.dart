import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_constants.dart';
import '../../core/app_logger.dart';
import '../../core/config/config_manager.dart';
import '../../models/wallpaper_model.dart';
import '../../services/ads_service.dart';
import '../../services/wallpaper_apply_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_palette.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_typography.dart';
import '../../widgets/bottom_action_buttons.dart';

class FullscreenPreviewScreen extends StatefulWidget {
  const FullscreenPreviewScreen({super.key, required this.wallpaper});

  final WallpaperModel wallpaper;

  @override
  State<FullscreenPreviewScreen> createState() =>
      _FullscreenPreviewScreenState();
}

class _FullscreenPreviewScreenState extends State<FullscreenPreviewScreen> {
  static final Set<int> _sessionUnlockedLiveWallpaperIds = <int>{};

  VideoPlayerController? _controller;
  final WallpaperApplyService _applyService = WallpaperApplyService();
  bool _ready = false;
  bool _hasError = false;
  bool _isApplying = false;
  bool _isSharing = false;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (_shouldRequireRewardedUnlock()) {
      unawaited(AdService.loadRewardedAd());
    }
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _ready = false;
        _hasError = false;
      });
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.wallpaper.imageUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;

    try {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.initialize().timeout(const Duration(seconds: 20));
      if (!identical(_controller, controller)) {
        await controller.dispose();
        return;
      }
      await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Fullscreen video init failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (identical(_controller, controller)) {
        _controller = null;
      }
      await controller.dispose();
      if (mounted) {
        setState(() {
          _ready = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _retry() async {
    final old = _controller;
    _controller = null;
    await old?.dispose();
    await _initialize();
  }

  Future<void> _shareWallpaper() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final response = await http.get(Uri.parse(widget.wallpaper.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${widget.wallpaper.name.replaceAll(RegExp(r'[^\w]'), '_')}.mp4';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: 'video/mp4')],
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

  Future<void> _applyWallpaper() async {
    if (_isApplying) return;

    setState(() => _isApplying = true);
    _showApplyingDialog();

    try {
      final message = await _applyService.applyLiveWallpaper(
        videoUrl: widget.wallpaper.imageUrl,
        fileName: widget.wallpaper.name,
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
            : 'Unable to apply live wallpaper.',
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _handleApplyTap() async {
    if (_isApplying || _isUnlocking) return;
    if (_isLiveWallpaperUnlocked) {
      await _applyWallpaper();
      return;
    }

    final bool wantsUnlock = await _showUnlockDialog() ?? false;
    if (!wantsUnlock || !mounted) return;

    debugPrint('AdService: Unlock Started. wallpaperId=${widget.wallpaper.id}');
    setState(() => _isUnlocking = true);
    final RewardedAdShowResult result = await AdService.showRewardedAd(
      loadTimeout: const Duration(seconds: 90),
    );
    if (!mounted) return;

    if (result != RewardedAdShowResult.rewarded) {
      debugPrint(
        'AdService: Unlock Failed. wallpaperId=${widget.wallpaper.id}, '
        'reason=$result',
      );
      setState(() => _isUnlocking = false);
      AppSnackbar.warning(
        result == RewardedAdShowResult.dismissedWithoutReward
            ? 'Watch the full ad to unlock this live wallpaper.'
            : 'Rewarded ad was not available. Please try again.',
      );
      return;
    }

    _sessionUnlockedLiveWallpaperIds.add(widget.wallpaper.id);
    debugPrint('AdService: Unlock Success. wallpaperId=${widget.wallpaper.id}');
    setState(() => _isUnlocking = false);
    AppSnackbar.success('Wallpaper unlocked. Applying wallpaper...');
    await _applyWallpaper();
  }

  bool get _isLiveWallpaperUnlocked {
    return !_shouldRequireRewardedUnlock() ||
        _sessionUnlockedLiveWallpaperIds.contains(widget.wallpaper.id);
  }

  bool _shouldRequireRewardedUnlock() {
    return ConfigManager.config.showAds &&
        ConfigManager.config.showRewardedAds &&
        ConfigManager.config.showRewardedOnLiveWallpaperUnlock;
  }

  Future<bool?> _showUnlockDialog() {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0xAA000000),
      builder: (ctx) {
        final palette = ctx.palette;
        return AlertDialog(
          backgroundColor: palette.obsidian,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: palette.hairline),
          ),
          title: Text(
            'UNLOCK LIVE WALLPAPER',
            style: AppText.display(
              size: 20,
              letterSpacing: 1.4,
              color: palette.bone,
            ),
          ),
          content: Text(
            'Watch a rewarded ad to unlock this live wallpaper for this session.',
            style: AppText.body(color: palette.ash),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('UNLOCK'),
            ),
          ],
        );
      },
    );
  }

  void _showApplyingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xAA000000),
      builder: (ctx) {
        final palette = ctx.palette;
        return Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
            decoration: BoxDecoration(
              color: palette.obsidian,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: palette.hairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.crimson,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'APPLYING',
                  style: AppText.button(color: palette.bone, size: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _applyService.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Always-visible thumbnail backdrop
          CachedNetworkImage(
            imageUrl: widget.wallpaper.thumbnailUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, _) => ColoredBox(color: palette.graphite),
            errorWidget: (_, _, _) => ColoredBox(color: palette.ink),
          ),

          // 2. Video plays over the thumbnail once ready
          if (_ready && controller != null && controller.value.isInitialized)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              opacity: 1,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

          // 3. Top gradient for badge legibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Close button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.close_rounded,
                    color: Color(0xFFF5F1E8),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // 5. Loading hint or error state
          if (!_ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 110,
              child: Center(
                child: _hasError
                    ? _ErrorPill(onRetry: _retry)
                    : const _LoadingPill(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomActionButtons(
        isApplying: _isApplying || _isUnlocking,
        onShare: () {
          if (!_isSharing) _shareWallpaper();
        },
        onApply: _handleApplyTap,
        applyLabel: _isLiveWallpaperUnlocked ? 'APPLY WALLPAPER' : 'UNLOCK',
        busyLabel: _isUnlocking ? 'UNLOCKING' : 'APPLYING',
        applyIcon: _isLiveWallpaperUnlocked
            ? Icons.bolt_rounded
            : Icons.lock_open_rounded,
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.crimson,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'LOADING MOTION',
            style: AppText.mono(size: 10.5, color: const Color(0xFFF5F1E8)),
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.crimson,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Color(0xFFF5F1E8),
              ),
              const SizedBox(width: 8),
              Text(
                'RETRY MOTION',
                style: AppText.button(size: 11, color: const Color(0xFFF5F1E8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
