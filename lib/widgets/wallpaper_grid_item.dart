import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper_model.dart';
import 'app_colors.dart';
import 'app_palette.dart';
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
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Hero(
      tag: 'wallpaper-${wallpaper.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: palette.obsidian,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.hairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
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
                    placeholder: (_, _) => _ImageSkeleton(palette: palette),
                    errorWidget: (_, _, _) => _ImageError(palette: palette),
                  ),
                  // Subtle vertical gradient for legibility of overlays
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.5, 1],
                        ),
                      ),
                    ),
                  ),
                  // Index — bottom-left
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: AppText.mono(
                        size: 11,
                        color: const Color(0xFFF5F1E8),
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
                                  color: Color(0xFFF5F1E8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: AppText.mono(
                                size: 9,
                                color: const Color(0xFFF5F1E8),
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
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
              color: isFavorite ? AppColors.crimson : const Color(0xFFF5F1E8),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.graphite,
      child: const Center(
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
  const _ImageError({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.graphite,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: palette.ash, size: 28),
      ),
    );
  }
}
