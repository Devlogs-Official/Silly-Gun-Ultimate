import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'app_palette.dart';

class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 320,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: palette.obsidian,
          highlightColor: palette.graphite,
          period: const Duration(milliseconds: 1400),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
