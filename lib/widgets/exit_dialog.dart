import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_typography.dart';

class ExitDialog {
  const ExitDialog._();

  static Future<void> show(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xAA000000),
      builder: (context) {
        final palette = context.palette;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            decoration: BoxDecoration(
              color: palette.obsidian,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.hairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 22, height: 2, color: AppColors.crimson),
                    const SizedBox(width: 10),
                    Text('EXIT', style: AppText.eyebrow()),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'LEAVE GALLERY?',
                  style: AppText.display(
                    size: 30,
                    letterSpacing: 1.2,
                    color: palette.bone,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your saved wallpapers stay with you for next time.',
                  style: AppText.body(color: palette.ash),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('STAY'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('EXIT'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }
}
