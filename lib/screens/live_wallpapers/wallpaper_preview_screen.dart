import 'dart:async';

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_exceptions.dart';
import '../../core/app_logger.dart';
import '../../models/wallpaper_model.dart';
import '../../services/wallpaper_apply_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_palette.dart';
import '../../widgets/app_typography.dart';
import '../../widgets/video_loader.dart';
import '../../widgets/wallpaper_thumbnail_strip.dart';
import 'fullscreen_preview_screen.dart';

class WallpaperPreviewScreen extends StatefulWidget {
  const WallpaperPreviewScreen({
    super.key,
    required this.wallpaper,
    required this.wallpapers,
    required this.initialIndex,
  });

  final WallpaperModel wallpaper;
  final List<WallpaperModel> wallpapers;
  final int initialIndex;

  @override
  State<WallpaperPreviewScreen> createState() => _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState extends State<WallpaperPreviewScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  final WallpaperApplyService _applyService = WallpaperApplyService();
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, String> _videoErrors = {};
  late int _selectedIndex;
  bool _didPrecacheDependencies = false;
  bool _routePaused = false;
  Timer? _pageChangeDebounce;

  Future<void> _onPageChanged(int index) async {
    _pageChangeDebounce?.cancel();
    _controllers[_selectedIndex]?.pause();
    if (!mounted) return;
    setState(() => _selectedIndex = index);

    _pageChangeDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _initializeVideo(index, play: true);
      if (!mounted) return;
      _preloadNearby(index);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialIndex.clamp(0, widget.wallpapers.length - 1);
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.82,
    );
    _initializeVideo(_selectedIndex, play: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheDependencies) return;
    _didPrecacheDependencies = true;
    _preloadNearby(_selectedIndex);
  }

  Future<void> _initializeVideo(int index, {required bool play}) async {
    if (index < 0 || index >= widget.wallpapers.length) return;
    _videoErrors.remove(index);

    final existing = _controllers[index];
    if (existing != null) {
      if (play) await existing.play();
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.wallpapers[index].imageUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controllers[index] = controller;

    try {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.initialize().timeout(const Duration(seconds: 18));
      if (!identical(_controllers[index], controller)) {
        await controller.dispose();
        return;
      }
      if (play && !_routePaused) await controller.play();
      if (mounted) setState(() {});
    } catch (error, stackTrace) {
      AppLogger.error(
        'Video initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      _controllers.remove(index);
      await controller.dispose();

      // Only show error UI for non-timeout failures
      final isTimeout = error is TimeoutException;
      if (!isTimeout) {
        _videoErrors[index] = error is VideoPlaybackException
            ? error.message
            : 'Video failed to load. Please try again.';
      }
      if (mounted) setState(() {});
    }
  }

  void _preloadNearby(int index) {
    final keep = {index - 1, index, index + 1};
    final disposeIndexes = _controllers.keys
        .where((i) => !keep.contains(i))
        .toList();
    for (final i in disposeIndexes) {
      _controllers.remove(i)?.dispose();
    }

    for (final nearbyIndex in [index - 1, index + 1]) {
      if (nearbyIndex >= 0 && nearbyIndex < widget.wallpapers.length) {
        precacheImage(
          CachedNetworkImageProvider(
            widget.wallpapers[nearbyIndex].thumbnailUrl,
          ),
          context,
        );
      }
    }
  }

  Future<void> _selectWallpaper(int index) async {
    if (index == _selectedIndex) return;
    if (!mounted) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _retryVideo(int index) async {
    _controllers.remove(index)?.dispose();
    if (mounted) {
      setState(() {
        _videoErrors.remove(index);
      });
    }
    await _initializeVideo(index, play: index == _selectedIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _controllers[_selectedIndex]?.pause();
      return;
    }
    if (state == AppLifecycleState.resumed && !_routePaused) {
      _controllers[_selectedIndex]?.play();
    }
  }

  void _pauseCurrentVideo() {
    _routePaused = true;
    _controllers[_selectedIndex]?.pause();
  }

  void _resumeCurrentVideo() {
    _routePaused = false;
    _controllers[_selectedIndex]?.play();
  }

  @override
  void dispose() {
    _pageChangeDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _applyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: palette.ink,
        appBar: AppBar(
          backgroundColor: palette.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(width: 22, height: 2, color: AppColors.crimson),
              const SizedBox(width: 10),
              Text('LIVE', style: AppText.eyebrow()),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: Center(
                child: Text(
                  '${(_selectedIndex + 1).toString().padLeft(2, '0')} / ${widget.wallpapers.length.toString().padLeft(2, '0')}',
                  style: AppText.mono(color: palette.bone),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.wallpapers.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final wallpaper = widget.wallpapers[index];
                    final active = index == _selectedIndex;
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      scale: active ? 1 : 0.9,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 18, 6, 14),
                        child: _PreviewCard(
                          wallpaper: wallpaper,
                          controller: _controllers[index],
                          active: active,
                          errorMessage: _videoErrors[index],
                          onRetry: () => _retryVideo(index),
                          onExpandOpen: _pauseCurrentVideo,
                          onExpandClosed: _resumeCurrentVideo,
                        ),
                      ),
                    );
                  },
                ),
              ),
              WallpaperThumbnailStrip(
                wallpapers: widget.wallpapers,
                selectedIndex: _selectedIndex,
                onSelected: _selectWallpaper,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.wallpaper,
    required this.controller,
    required this.active,
    required this.errorMessage,
    required this.onRetry,
    required this.onExpandOpen,
    required this.onExpandClosed,
  });

  final WallpaperModel wallpaper;
  final VideoPlayerController? controller;
  final bool active;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onExpandOpen;
  final VoidCallback onExpandClosed;

  @override
  Widget build(BuildContext context) {
    final ready = controller?.value.isInitialized == true;
    final hasError = errorMessage != null;
    final palette = context.palette;

    return Hero(
      tag: 'wallpaper-${wallpaper.id}',
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      child: ready
                          ? SizedBox.expand(
                              key: const ValueKey('video'),
                              child: FittedBox(
                                clipBehavior: Clip.hardEdge,
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: controller!.value.size.width,
                                  height: controller!.value.size.height,
                                  child: VideoPlayer(controller!),
                                ),
                              ),
                            )
                          : SizedBox.expand(
                              key: const ValueKey('thumb'),
                              child: CachedNetworkImage(
                                imageUrl: wallpaper.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const VideoLoader(),
                                errorWidget: (_, _, _) => ColoredBox(
                                  color: palette.graphite,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: palette.ash,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Crimson corner accent
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 32,
                        height: 4,
                        color: AppColors.crimson,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 4,
                        height: 32,
                        color: AppColors.crimson,
                      ),
                    ),
                    if (hasError)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.62),
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_disabled_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: OpenContainer<void>(
                transitionType: ContainerTransitionType.fadeThrough,
                transitionDuration: const Duration(milliseconds: 460),
                closedElevation: 0,
                openElevation: 0,
                closedColor: AppColors.crimson,
                openColor: palette.ink,
                onClosed: (_) => onExpandClosed(),
                closedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                openBuilder: (_, _) =>
                    FullscreenPreviewScreen(wallpaper: wallpaper),
                closedBuilder: (_, openContainer) {
                  return InkWell(
                    onTap: () {
                      onExpandOpen();
                      openContainer();
                    },
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.fullscreen_rounded,
                            color: Color(0xFFF5F1E8),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'FULLSCREEN PREVIEW',
                            style: AppText.button(
                              size: 12.5,
                              color: const Color(0xFFF5F1E8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFF5F1E8),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
