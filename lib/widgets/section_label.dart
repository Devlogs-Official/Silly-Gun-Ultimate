import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_typography.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.eyebrow,
    required this.headline,
    this.trailing,
  });

  final String eyebrow;
  final String headline;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 2,
              color: AppColors.crimson,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                eyebrow.toUpperCase(),
                style: AppText.eyebrow(),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppText.mono(color: palette.smoke),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          headline,
          style: AppText.display(
            size: 32,
            letterSpacing: 1.4,
            color: palette.bone,
          ),
        ),
      ],
    );
  }
}
