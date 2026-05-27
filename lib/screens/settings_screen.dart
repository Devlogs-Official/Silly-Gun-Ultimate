import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../providers/favorites_provider.dart';
import '../providers/wallpaper_provider.dart';
import '../services/settings_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_palette.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_typography.dart';
import '../widgets/section_label.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.ink,
      appBar: AppBar(
        backgroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: palette.bone,
        ),
        titleSpacing: 0,
        title: Text(
          'SETTINGS',
          style: AppText.button(color: palette.bone, size: 13),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
          children: const [
            SectionLabel(
              eyebrow: 'PREFERENCES',
              headline: 'CONTROL',
              trailing: '04 GROUPS',
            ),
            SizedBox(height: 22),
            _GroupLabel('01 · APPEARANCE'),
            SizedBox(height: 10),
            _ThemeCard(),
            SizedBox(height: 26),
            _GroupLabel('02 · APPLY TARGET'),
            SizedBox(height: 10),
            _ApplyTargetCard(),
            SizedBox(height: 26),
            _GroupLabel('03 · STORAGE'),
            SizedBox(height: 10),
            _StorageCard(),
            SizedBox(height: 26),
            _GroupLabel('04 · INFO'),
            SizedBox(height: 10),
            _AboutCard(),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: AppText.mono(size: 10, color: context.palette.smoke),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.obsidian,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.hairline),
      ),
      child: child,
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final current = settings.themeMode;
    final palette = context.palette;
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THEME MODE',
              style: AppText.button(color: palette.bone, size: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Switch the gallery between light and dark.',
              style: AppText.body(size: 13, color: palette.ash),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ThemeChip(
                    icon: Icons.light_mode_rounded,
                    label: 'LIGHT',
                    selected: current == AppThemeMode.light,
                    onTap: () => settings.setThemeMode(AppThemeMode.light),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ThemeChip(
                    icon: Icons.dark_mode_rounded,
                    label: 'DARK',
                    selected: current == AppThemeMode.dark,
                    onTap: () => settings.setThemeMode(AppThemeMode.dark),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ThemeChip(
                    icon: Icons.brightness_auto_rounded,
                    label: 'SYSTEM',
                    selected: current == AppThemeMode.system,
                    onTap: () => settings.setThemeMode(AppThemeMode.system),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? AppColors.crimson : palette.graphite,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.crimson : palette.hairline,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFFF5F1E8) : palette.bone,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppText.button(
                  color:
                      selected ? const Color(0xFFF5F1E8) : palette.ash,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyTargetCard extends StatelessWidget {
  const _ApplyTargetCard();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final current = settings.applyTarget;
    final palette = context.palette;
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHERE TO APPLY',
              style: AppText.button(color: palette.bone, size: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the default surface for new wallpapers.',
              style: AppText.body(size: 13, color: palette.ash),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ApplyTargetChip(
                    icon: Icons.home_rounded,
                    label: 'HOME',
                    selected: current == ApplyTarget.home,
                    onTap: () => settings.setApplyTarget(ApplyTarget.home),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ApplyTargetChip(
                    icon: Icons.lock_rounded,
                    label: 'LOCK',
                    selected: current == ApplyTarget.lock,
                    onTap: () => settings.setApplyTarget(ApplyTarget.lock),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ApplyTargetChip(
                    icon: Icons.phone_android_rounded,
                    label: 'BOTH',
                    selected: current == ApplyTarget.both,
                    onTap: () => settings.setApplyTarget(ApplyTarget.both),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyTargetChip extends StatelessWidget {
  const _ApplyTargetChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? AppColors.crimson : palette.graphite,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.crimson : palette.hairline,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFFF5F1E8) : palette.bone,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppText.button(
                  color:
                      selected ? const Color(0xFFF5F1E8) : palette.ash,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard();

  Future<void> _clearCache(BuildContext context) async {
    final wallpaperProvider = context.read<WallpaperProvider>();
    final confirmed = await _confirm(
      context,
      title: 'CLEAR CACHE?',
      message:
          'This removes downloaded wallpaper data. Your favorites are kept.',
      confirmLabel: 'CLEAR',
    );
    if (!confirmed) return;
    try {
      await wallpaperProvider.clearCacheAndReset();
      AppSnackbar.success('Cache cleared.');
    } catch (error, stackTrace) {
      AppLogger.error('Cache clear failed', error: error, stackTrace: stackTrace);
      AppSnackbar.error('Unable to clear cache.');
    }
  }

  Future<void> _clearFavorites(BuildContext context) async {
    final favoritesProvider = context.read<FavoritesProvider>();
    final confirmed = await _confirm(
      context,
      title: 'REMOVE ALL FAVORITES?',
      message: 'Every wallpaper saved to your library will be removed.',
      confirmLabel: 'REMOVE',
    );
    if (!confirmed) return;
    try {
      await favoritesProvider.clearFavorites();
      AppSnackbar.success('Favorites cleared.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Favorites clear failed',
        error: error,
        stackTrace: stackTrace,
      );
      AppSnackbar.error('Unable to clear favorites.');
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final palette = context.palette;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xAA000000),
      builder: (ctx) {
        return Dialog(
          backgroundColor: palette.obsidian,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: palette.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 22, height: 2, color: AppColors.crimson),
                    const SizedBox(width: 10),
                    Text('CONFIRM', style: AppText.eyebrow()),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppText.display(
                    size: 26,
                    letterSpacing: 1.2,
                    color: palette.bone,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message, style: AppText.body(color: palette.ash)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(confirmLabel),
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.cleaning_services_rounded,
            title: 'CLEAR CACHED WALLPAPERS',
            subtitle: 'Free up space. Favorites are kept.',
            onTap: () => _clearCache(context),
          ),
          Divider(height: 1, color: context.palette.hairline),
          _ActionTile(
            icon: Icons.favorite_outline_rounded,
            title: 'CLEAR FAVORITES',
            subtitle: 'Empty your saved library.',
            onTap: () => _clearFavorites(context),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.crimson,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFF5F1E8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName.toUpperCase(),
                        style: AppText.button(
                          color: palette.bone,
                          size: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'VERSION ${AppConstants.appVersion} · BUILD 02',
                        style: AppText.mono(color: palette.ash, size: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.graphite,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: palette.hairline),
              ),
              child: Icon(icon, color: AppColors.crimson, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.button(color: palette.bone, size: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppText.body(size: 12.5, color: palette.ash)),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: palette.ash,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
