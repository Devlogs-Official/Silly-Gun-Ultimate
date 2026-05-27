import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../widgets/app_colors.dart';
import '../../widgets/app_typography.dart';

class LiveWallpaperCard extends StatefulWidget {
  const LiveWallpaperCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<LiveWallpaperCard> createState() => _LiveWallpaperCardState();
}

class _LiveWallpaperCardState extends State<LiveWallpaperCard>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    _controller = VideoPlayerController.asset('assets/utils/hero-silly.mp4')
      ..initialize().then((_) async {
        if (!mounted) return;
        await _controller!.setLooping(true);
        await _controller!.setVolume(0);
        if (!_controller!.value.isPlaying) {
          await _controller!.play();
        }
        if (!mounted) return;
        setState(() => _isReady = true);
      }).catchError((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: widget.onTap,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.obsidian,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.hairline),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isReady &&
                        _controller != null &&
                        _controller!.value.isInitialized)
                      AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      ),

                    // Crimson left rail
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 3, color: AppColors.crimson),
                    ),

                    // Dark gradient
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.ink.withValues(alpha: 0.85),
                            AppColors.ink.withValues(alpha: 0.45),
                            AppColors.ink.withValues(alpha: 0.05),
                          ],
                          stops: const [0, 0.5, 1],
                        ),
                      ),
                    ),

                    // Top corner stat
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: AppColors.bone.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 6,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.crimson,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: AppText.mono(
                                size: 9.5,
                                color: AppColors.bone,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Headline + CTA
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FEATURED',
                            style: AppText.eyebrow(
                              color: AppColors.crimson,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MOTION',
                            style: AppText.display(
                              size: 42,
                              letterSpacing: 0.8,
                              height: 0.9,
                            ),
                          ),
                          Text(
                            'GALLERY',
                            style: AppText.display(
                              size: 42,
                              letterSpacing: 0.8,
                              height: 0.9,
                              color: AppColors.crimson,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'EXPLORE LIVE',
                                style: AppText.button(
                                  size: 11,
                                  color: AppColors.bone,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.crimson,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.bone,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (!_isReady)
                      const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
