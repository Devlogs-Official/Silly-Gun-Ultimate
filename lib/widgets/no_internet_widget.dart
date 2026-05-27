import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class NoInternetWidget extends StatefulWidget {
  const NoInternetWidget({
    super.key,
    required this.onRetry,
    this.onExit,
    this.isRetrying = false,
  });

  final VoidCallback onRetry;
  final VoidCallback? onExit;
  final bool isRetrying;

  @override
  State<NoInternetWidget> createState() => _NoInternetWidgetState();
}

class _NoInternetWidgetState extends State<NoInternetWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.obsidian,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AppColors.crimson),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.crimson,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 22, height: 2, color: AppColors.crimson),
                const SizedBox(width: 10),
                Text('OFFLINE', style: AppText.eyebrow()),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'NO SIGNAL',
              textAlign: TextAlign.center,
              style: AppText.display(size: 40, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppText.body(),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: widget.isRetrying ? null : widget.onRetry,
              icon: widget.isRetrying
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
            if (widget.onExit != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: widget.isRetrying ? null : widget.onExit,
                child: const Text('EXIT'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
