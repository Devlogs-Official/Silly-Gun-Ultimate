import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/wallpaper_model.dart';

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
  static const double _horizontalPadding = 18;
  static const double _itemWidth = 90;
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
    final selectedCenter =
        _horizontalPadding +
        (widget.selectedIndex * (_itemWidth + _itemGap)) +
        (_itemWidth / 2);
    final target = selectedCenter - (position.viewportDimension / 2);
    final double clampedTarget = target
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();

    if ((position.pixels - clampedTarget).abs() < 1) {
      return;
    }

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
    return SizedBox(
      height: 92,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        physics: const BouncingScrollPhysics(),
        itemCount: widget.wallpapers.length,
        separatorBuilder: (context, index) => const SizedBox(width: _itemGap),
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
                  width: isSelected ? 78 : 66,
                  height: isSelected ? 78 : 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFB00020)
                          : Colors.transparent,
                      width: 3,
                    ),

                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(
                            0xFFB00020,
                          ).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: wallpaper.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      fadeInDuration: const Duration(milliseconds: 220),
                      placeholder: (context, url) => const _ThumbShimmer(),
                      errorWidget: (context, url, error) => const ColoredBox(
                        color: Color(0xFF181C24),
                        child: Icon(Icons.broken_image_outlined, size: 18),
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
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) =>
            const SizedBox(width: 58, child: _ThumbShimmer()),
      ),
    );
  }
}

class _ThumbShimmer extends StatelessWidget {
  const _ThumbShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF171B24),
      highlightColor: const Color(0xFF2B3444),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
