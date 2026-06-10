import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:silly_gun_ultimate/core/app_constants.dart';

import '../../core/app_logger.dart';
import '../../core/config/config_manager.dart';
import '../../models/wallpaper_model.dart';
import '../../services/ads_service.dart';
import '../../services/settings_service.dart';
import '../../services/wallpaper_apply_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_palette.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_typography.dart';
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
    if (_isApplying) return;
    if (ConfigManager.config.showAds &&
        ConfigManager.config.showInterstitialAds &&
        ConfigManager.config.showInterstitialOnApplyWallpaper) {
      await AdService.showInterstitialAd();
      if (!mounted) return;
    }

    final selectedTarget = await showModalBottomSheet<ApplyTarget>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (ctx) {
        return _ApplyTargetSheet(
          currentTarget: context.read<SettingsService>().applyTarget,
        );
      },
    );
    if (!mounted || selectedTarget == null) return;

    await _applyWallpaper(selectedTarget.wallpaperManagerLocation);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.ink,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.wallpaper.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, _) => const VideoLoader(borderRadius: 0),
              errorWidget: (_, _, _) => Center(
                child: Icon(Icons.broken_image, color: palette.ash, size: 40),
              ),
            ),
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

class _ApplyTargetSheet extends StatelessWidget {
  const _ApplyTargetSheet({required this.currentTarget});

  final ApplyTarget currentTarget;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.ink,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          border: Border(top: BorderSide(color: palette.hairline)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 22, height: 2, color: AppColors.crimson),
                const SizedBox(width: 10),
                Text('APPLY TO', style: AppText.eyebrow(color: palette.ash)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'CHOOSE SCREEN',
              style: AppText.display(
                size: 26,
                letterSpacing: 1.2,
                color: palette.bone,
              ),
            ),
            const SizedBox(height: 16),
            _ApplyTargetTile(
              icon: Icons.home_rounded,
              label: 'HOME SCREEN',
              selected: currentTarget == ApplyTarget.home,
              onTap: () => Navigator.of(context).pop(ApplyTarget.home),
            ),
            const SizedBox(height: 10),
            _ApplyTargetTile(
              icon: Icons.lock_rounded,
              label: 'LOCK SCREEN',
              selected: currentTarget == ApplyTarget.lock,
              onTap: () => Navigator.of(context).pop(ApplyTarget.lock),
            ),
            const SizedBox(height: 10),
            _ApplyTargetTile(
              icon: Icons.phone_android_rounded,
              label: 'BOTH SCREENS',
              selected: currentTarget == ApplyTarget.both,
              onTap: () => Navigator.of(context).pop(ApplyTarget.both),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyTargetTile extends StatelessWidget {
  const _ApplyTargetTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? AppColors.crimson : palette.obsidian,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: selected ? AppColors.crimson : palette.hairline,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFFF5F1E8) : AppColors.crimson,
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppText.button(
                    color: selected ? const Color(0xFFF5F1E8) : palette.bone,
                    size: 12,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: selected ? const Color(0xFFF5F1E8) : palette.ash,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
