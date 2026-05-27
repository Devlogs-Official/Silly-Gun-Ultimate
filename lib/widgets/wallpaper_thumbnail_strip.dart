import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/wallpaper_model.dart';
import 'app_colors.dart';

class WallpaperThumbnailStrip extends StatefulWidget {
  const WallpaperThumbnailStrip({
    super.key,
    required this.wallpapers,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<WallpaperModel> wallpapers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<WallpaperThumbnailStrip> createState() =>
      _WallpaperThumbnailStripState();
}

class _WallpaperThumbnailStripState extends State<WallpaperThumbnailStrip> {
  static const double _horizontalPadding = 22;
  static const double _itemWidth = 76;
  static const double _itemGap = 10;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedIntoView(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant WallpaperThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.wallpapers.length != widget.wallpapers.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollSelectedIntoView();
      });
    }
  }

  void _scrollSelectedIntoView({bool animate = true}) {
    if (!mounted ||
        !_scrollController.hasClients ||
        widget.wallpapers.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.wallpapers.length) {
      return;
    }

    final position = _scrollController.position;
    final selectedCenter = _horizontalPadding +
        (widget.selectedIndex * (_itemWidth + _itemGap)) +
        (_itemWidth / 2);
    final target = selectedCenter - (position.viewportDimension / 2);
    final double clampedTarget =
        target.clamp(0.0, position.maxScrollExtent).toDouble();

    if ((position.pixels - clampedTarget).abs() < 1) return;

    if (animate) {
      _scrollController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _scrollController.jumpTo(clampedTarget);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      color: AppColors.ink,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        physics: const BouncingScrollPhysics(),
        itemCount: widget.wallpapers.length,
        separatorBuilder: (_, _) => const SizedBox(width: _itemGap),
        itemBuilder: (context, index) {
          final wallpaper = widget.wallpapers[index];
          final bool isSelected = index == widget.selectedIndex;
          return SizedBox(
            width: _itemWidth,
            child: Center(
              child: GestureDetector(
                onTap: () => widget.onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 76 : 60,
                  height: isSelected ? 76 : 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.crimson
                          : AppColors.hairline,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CachedNetworkImage(
                      imageUrl: wallpaper.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      fadeInDuration: const Duration(milliseconds: 220),
                      placeholder: (_, _) => const _ThumbShimmer(),
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: AppColors.graphite,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 16,
                          color: AppColors.ash,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ThumbnailStripShimmer extends StatelessWidget {
  const ThumbnailStripShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) =>
            const SizedBox(width: 60, child: _ThumbShimmer()),
      ),
    );
  }
}

class _ThumbShimmer extends StatelessWidget {
  const _ThumbShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.obsidian,
      highlightColor: AppColors.graphite,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
      ),
    );
  }
}
