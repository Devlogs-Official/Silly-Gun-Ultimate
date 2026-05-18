import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper_model.dart';

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
    final double height = index.isEven ? 250 : 320;

    return Hero(
      tag: 'wallpaper-${wallpaper.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CachedNetworkImage(
                    imageUrl: wallpaper.thumbnailUrl,
                    fit: BoxFit.cover,
                    fadeInDuration:
                    const Duration(milliseconds: 260),
                    placeholder: (context, url) =>
                    const _ImageSkeleton(),
                    errorWidget: (context, url, error) =>
                    const _ImageError(),
                  ),

                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.transparent,
                            Colors.black.withValues(
                              alpha: 0.08,
                            ),
                            Colors.black.withValues(
                              alpha: 0.62,
                            ),
                          ],
                          stops: const <double>[
                            0.45,
                            0.72,
                            1,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onFavoriteToggle,
                    ),
                  ),

                  if (showTypeBadge)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius:
                              BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  wallpaper.isLive
                                      ? Icons
                                      .live_tv
                                      : null,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  wallpaper.isLive
                                      ? 'Live'
                                      : '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                    color:
                                    Colors.white,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                    letterSpacing:
                                    0.5,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (
                child,
                animation,
                ) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isFavorite),
              color: isFavorite
                  ? const Color(0xFFFF5C8A)
                  : Colors.white,
              size: 22,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFFFFD1DC),
            const Color(0xFFFFB3C7),
          ],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Colors.white,
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
      color: Color(0xFFFFE6EC),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Color(0xFFFF7597),
          size: 34,
        ),
      ),
    );
  }
}