import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/wallpaper_provider.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_palette.dart';
import '../widgets/app_typography.dart';
import 'app_drawer.dart';
import 'favorites_screen.dart';
import 'static_wallpapers/home_screen.dart';
import 'live_wallpapers/live_wallpapers_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  Future<bool> _handleBackPress() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }

    final bool shouldExit = await _showExitDialog();
    if (shouldExit) {
      await SystemNavigator.pop();
    }
    return false;
  }

  Future<bool> _showExitDialog() async {
    final bool? result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exit App',
      barrierColor: const Color(0xAA000000),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => const _ExitAppDialog(),
      transitionBuilder: (context, animation, _, child) {
        final CurvedAnimation curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }

  List<Widget> get _screens => <Widget>[
        HomeScreen(onOpenLiveTab: () => setState(() => _selectedIndex = 1)),
        const LiveWallpapersScreen(),
        const FavoritesScreen(),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<WallpaperProvider>();
      provider.fetchInitialWallpapers(isLive: true);
      provider.fetchInitialWallpapers(isLive: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: palette.ink,
        extendBody: true,
        drawer: const ModernDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedIndex),
            child: _screens[_selectedIndex],
          ),
        ),
        bottomNavigationBar: _FloatingNavBar(
          selectedIndex: _selectedIndex,
          onTap: (index) {
            if (index == _selectedIndex) return;
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      label: 'HOME',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _NavItem(
      label: 'LIVE',
      icon: Icons.play_circle_outline_rounded,
      activeIcon: Icons.play_circle_fill_rounded,
    ),
    _NavItem(
      label: 'SAVED',
      icon: Icons.bookmark_outline_rounded,
      activeIcon: Icons.bookmark_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        8 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(56),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 68,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.obsidian.withValues(alpha: isDark ? 0.86 : 0.92),
              borderRadius: BorderRadius.circular(56),
              border: Border.all(color: palette.hairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = index == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.crimson
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(48),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.crimson
                                      .withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 24,
                            color: selected
                                ? const Color(0xFFF5F1E8)
                                : palette.ash,
                          ),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.label,
                              style: AppText.button(
                                color: const Color(0xFFF5F1E8),
                                size: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _ExitAppDialog extends StatelessWidget {
  const _ExitAppDialog();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: palette.obsidian,
              border: Border.all(color: palette.hairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
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
                const SizedBox(height: 14),
                Text(
                  'LEAVE GALLERY?',
                  style: AppText.display(
                    size: 32,
                    letterSpacing: 1.2,
                    color: palette.bone,
                  ),
                ),
                const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
