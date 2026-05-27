import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_typography.dart';

enum AppSnackbarType { success, error, warning, internet }

class AppSnackbar {
  const AppSnackbar._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void success(String message) {
    _show(message, AppSnackbarType.success);
  }

  static void error(String message) {
    _show(message, AppSnackbarType.error);
  }

  static void warning(String message) {
    _show(message, AppSnackbarType.warning);
  }

  static void internet(String message) {
    _show(message, AppSnackbarType.internet);
  }

  static void _show(String message, AppSnackbarType type) {
    final style = switch (type) {
      AppSnackbarType.success => const _SnackbarStyle(
          icon: Icons.check_rounded,
          accent: AppColors.crimson,
          label: 'OK',
        ),
      AppSnackbarType.error => const _SnackbarStyle(
          icon: Icons.priority_high_rounded,
          accent: AppColors.crimson,
          label: 'ERR',
        ),
      AppSnackbarType.warning => const _SnackbarStyle(
          icon: Icons.warning_amber_rounded,
          accent: AppColors.emberGlow,
          label: 'WARN',
        ),
      AppSnackbarType.internet => const _SnackbarStyle(
          icon: Icons.wifi_off_rounded,
          accent: AppColors.crimsonDeep,
          label: 'NET',
        ),
    };

    void showNow() {
      final messenger = messengerKey.currentState;
      if (messenger == null) return;
      final navigatorContext = messenger.context;
      final palette = AppPalette.of(navigatorContext);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            elevation: 0,
            backgroundColor: Colors.transparent,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            duration: const Duration(seconds: 3),
            padding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: palette.obsidian,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: palette.hairline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: style.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          color: const Color(0xFFF5F1E8),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          style.label,
                          style: AppText.mono(
                            size: 9.5,
                            color: const Color(0xFFF5F1E8),
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: AppText.body(
                        color: palette.bone,
                        size: 13.5,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      showNow();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => showNow());
  }
}

class _SnackbarStyle {
  const _SnackbarStyle({
    required this.icon,
    required this.accent,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String label;
}
