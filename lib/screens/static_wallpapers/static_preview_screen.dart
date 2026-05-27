import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/wallpaper_model.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_palette.dart';
import '../../widgets/app_typography.dart';
import '../../widgets/wallpaper_thumbnail_strip.dart';
import 'static_full_preview.dart';

class StaticPreviewScreen extends StatefulWidget {
  const StaticPreviewScreen({
    super.key,
    required this.wallpaper,
    required this.wallpapers,
    required this.initialIndex,
  });

  final WallpaperModel wallpaper;
  final List<WallpaperModel> wallpapers;
  final int initialIndex;

  @override
  State<StaticPreviewScreen> createState() => _StaticPreviewScreenState();
}

class _StaticPreviewScreenState extends State<StaticPreviewScreen> {
  late final PageController _pageController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.wallpapers.length - 1);
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.82,
    );
  }

  Future<void> _selectWallpaper(int index) async {
    if (index == _selectedIndex) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
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
            Text('STATIC', style: AppText.eyebrow()),
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
                  final bool active = index == _selectedIndex;
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    scale: active ? 1 : 0.9,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 18, 6, 14),
                      child: _PreviewCard(wallpaper: wallpaper),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.wallpaper});

  final WallpaperModel wallpaper;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Hero(
      tag: 'wallpaper-${wallpaper.id}',
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.obsidian,
                    border: Border.all(color: palette.hairline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.32),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: wallpaper.imageUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 240),
                        placeholder: (_, _) => ColoredBox(
                          color: palette.graphite,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.crimson,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => ColoredBox(
                          color: palette.graphite,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 42,
                              color: palette.ash,
                            ),
                          ),
                        ),
                      ),
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
                    ],
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
                closedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                openBuilder: (_, _) =>
                    StaticFullScreenPreview(wallpaper: wallpaper),
                closedBuilder: (_, openContainer) {
                  return InkWell(
                    onTap: openContainer,
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
