import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper_model.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class WallpaperGridItem extends StatelessWidget {
  const WallpaperGridItem({
    super.key,
    required this.wallpaper,
    required this.index,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.showTypeBadge = true,
  });

  final WallpaperModel wallpaper;
  final int index;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final bool showTypeBadge;

  @override
  Widget build(BuildContext context) {
    final double height = index.isEven ? 240 : 320;

    return Hero(
      tag: 'wallpaper-${wallpaper.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: height,
            decoration: BoxDecoration(
              color: AppColors.obsidian,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.hairline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: wallpaper.thumbnailUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 260),
                    placeholder: (_, _) => const _ImageSkeleton(),
                    errorWidget: (_, _, _) => const _ImageError(),
                  ),

                  // Subtle vertical gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.ink.withValues(alpha: 0.55),
                          ],
                          stops: const [0.5, 1],
                        ),
                      ),
                    ),
                  ),

                  // Index badge — bottom-left
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: AppText.mono(
                        size: 11,
                        color: AppColors.bone,
                      ),
                    ),
                  ),

                  // Live badge — bottom-right
                  if (showTypeBadge && wallpaper.isLive)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimson,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 5,
                              height: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.bone,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: AppText.mono(
                                size: 9,
                                color: AppColors.bone,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Favorite — top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onFavoriteToggle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isFavorite),
              color: isFavorite ? AppColors.crimson : AppColors.bone,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.graphite,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.crimson,
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.graphite,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.ash,
          size: 28,
        ),
      ),
    );
  }
}
