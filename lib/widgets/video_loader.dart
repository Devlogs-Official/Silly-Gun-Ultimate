import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'app_palette.dart';

class VideoLoader extends StatelessWidget {
  const VideoLoader({
    super.key,
    this.borderRadius = 4,
  });

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Shimmer.fromColors(
      baseColor: palette.obsidian,
      highlightColor: palette.graphite,
      period: const Duration(milliseconds: 1400),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
