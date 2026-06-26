import 'package:flutter/material.dart';

import '../models/wallpaper_model.dart';
import '../services/ads_service.dart';
import 'app_palette.dart';

typedef WallpaperGridCardBuilder =
    Widget Function(BuildContext context, WallpaperModel wallpaper, int index);

class WallpaperGridWithNativeAds extends StatelessWidget {
  const WallpaperGridWithNativeAds({
    super.key,
    required this.wallpapers,
    required this.itemBuilder,
    required this.showNativeAds,
    required this.nativeInterval,
    required this.nativePlacement,
    this.padding = EdgeInsets.zero,
    this.footer,
    this.scrollable = false,
  });

  static const double cardHeight = 260;
  static const double nativeAdHeight = 400;
  static const double spacing = 14;

  final List<WallpaperModel> wallpapers;
  final WallpaperGridCardBuilder itemBuilder;
  final bool showNativeAds;
  final int nativeInterval;
  final String nativePlacement;
  final EdgeInsetsGeometry padding;
  final Widget? footer;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        children: [
          ..._buildRows(context),
          if (footer != null) ...[const SizedBox(height: spacing), footer!],
        ],
      ),
    );

    if (!scrollable) {
      return content;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [content],
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    final children = <Widget>[];
    int index = 0;
    int nextNativeAdAt = nativeInterval;

    while (index < wallpapers.length) {
      final firstIndex = index;
      final secondIndex = index + 1;

      children.add(
        SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: itemBuilder(context, wallpapers[firstIndex], firstIndex),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: secondIndex < wallpapers.length
                    ? itemBuilder(context, wallpapers[secondIndex], secondIndex)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );

      index += 2;
      final bool shouldShowNativeAd =
          showNativeAds &&
          nativeInterval > 0 &&
          index < wallpapers.length &&
          index >= nextNativeAdAt;

      if (shouldShowNativeAd) {
        nextNativeAdAt += nativeInterval;
        children.add(const SizedBox(height: 28));
        children.add(
          _GridNativeAd(
            key: ValueKey<String>('$nativePlacement-$index'),
            placement: nativePlacement,
          ),
        );
        children.add(const SizedBox(height: 28));
      } else if (index < wallpapers.length) {
        children.add(const SizedBox(height: spacing));
      }
    }

    return children;
  }
}

class _GridNativeAd extends StatelessWidget {
  const _GridNativeAd({super.key, required this.placement});

  final String placement;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: palette.hairline),
        ),
        child: NativeAdWidget(
          placement: placement,
          height: WallpaperGridWithNativeAds.nativeAdHeight,
        ),
      ),
    );
  }
}
