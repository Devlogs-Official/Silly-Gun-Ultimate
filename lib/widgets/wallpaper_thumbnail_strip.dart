import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/wallpaper_model.dart';

class WallpaperThumbnailStrip extends StatelessWidget {
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
  Widget build(BuildContext context) {

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: wallpapers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final wallpaper = wallpapers[index];
          final selected = index == selectedIndex;
          final bool isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 6),
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
                      color: const Color(0xFFB00020).withOpacity(0.35),
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
                  width: isSelected ? 78 : 66,
                  height: isSelected ? 78 : 66,
                ),
              ),
            ),
            // AnimatedContainer(
            //   duration: const Duration(milliseconds: 220),
            //   width: 58,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(
            //       color: selected ? Colors.white : const Color(0x22FFFFFF),
            //       width: selected ? 2.4 : 1,
            //     ),
            //     boxShadow: [
            //       if (selected)
            //         BoxShadow(
            //           color: Colors.white.withValues(alpha: 0.2),
            //           blurRadius: 16,
            //           offset: const Offset(0, 8),
            //         ),
            //     ],
            //   ),
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(13),
            //     child: Hero(
            //       tag: 'wallpaper-thumb-${wallpaper.id}',
            //       child: CachedNetworkImage(
            //         imageUrl: wallpaper.thumbnailUrl,
            //         fit: BoxFit.cover,
            //         fadeInDuration: const Duration(milliseconds: 220),
            //         placeholder: (context, url) => const _ThumbShimmer(),
            //         errorWidget: (context, url, error) => const ColoredBox(
            //           color: Color(0xFF181C24),
            //           child: Icon(Icons.broken_image_outlined, size: 18),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
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
        itemBuilder: (context, index) => const SizedBox(
          width: 58,
          child: _ThumbShimmer(),
        ),
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
