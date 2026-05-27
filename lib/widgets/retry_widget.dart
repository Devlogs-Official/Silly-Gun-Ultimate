import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class RetryWidget extends StatelessWidget {
  const RetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'SOMETHING WENT WRONG',
    this.isRetrying = false,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.obsidian,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.hairline),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.crimson,
                size: 32,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 22, height: 2, color: AppColors.crimson),
                const SizedBox(width: 10),
                Text('ERROR', style: AppText.eyebrow()),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppText.display(size: 28, letterSpacing: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: isRetrying ? null : onRetry,
              icon: isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('TRY AGAIN'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
