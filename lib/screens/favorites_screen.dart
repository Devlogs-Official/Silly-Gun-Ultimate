import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:silly_gun_ultimate/screens/static_wallpapers/static_preview_screen.dart';

import '../models/wallpaper_model.dart';
import '../providers/favorites_provider.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_palette.dart';
import '../widgets/app_typography.dart';
import '../widgets/section_label.dart';
import '../widgets/wallpaper_grid_item.dart';
import 'live_wallpapers/wallpaper_preview_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;
    final staticFavorites =
        favorites.where((item) => !item.isLive).toList(growable: false);
    final liveFavorites =
        favorites.where((item) => item.isLive).toList(growable: false);

    final activeList = _tabIndex == 0 ? staticFavorites : liveFavorites;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
              child: SectionLabel(
                eyebrow: 'YOUR LIBRARY',
                headline: 'SAVED',
                trailing:
                    '${favorites.length.toString().padLeft(2, '0')} ITEMS',
              ),
            ),
            _SegmentedTabs(
              tabs: [
                _TabModel(label: 'STATIC', count: staticFavorites.length),
                _TabModel(label: 'LIVE', count: liveFavorites.length),
              ],
              selectedIndex: _tabIndex,
              onChange: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 14),
            Expanded(child: _FavoritesGrid(items: activeList)),
          ],
        ),
      ),
    );
  }
}

class _TabModel {
  const _TabModel({required this.label, required this.count});

  final String label;
  final int count;
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChange,
  });

  final List<_TabModel> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: palette.obsidian,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final t = tabs[i];
            final selected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChange(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.crimson : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.label,
                        style: AppText.button(
                          size: 11,
                          color: selected
                              ? const Color(0xFFF5F1E8)
                              : palette.ash,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.16)
                              : palette.graphite,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          t.count.toString().padLeft(2, '0'),
                          style: AppText.mono(
                            size: 9.5,
                            color: selected
                                ? const Color(0xFFF5F1E8)
                                : palette.ash,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.items});

  final List<WallpaperModel> items;

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final palette = context.palette;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bookmark_outline_rounded,
                color: AppColors.crimson,
                size: 56,
              ),
              const SizedBox(height: 14),
              Text(
                'NOTHING SAVED',
                style: AppText.display(
                  size: 28,
                  letterSpacing: 2.4,
                  color: palette.bone,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart on any wallpaper to add it here.',
                textAlign: TextAlign.center,
                style: AppText.body(color: palette.ash),
              ),
            ],
          ),
        ),
      );
    }

    return MasonryGridView.count(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final wallpaper = items[index];
        return WallpaperGridItem(
          key: ValueKey('fav-${wallpaper.id}'),
          wallpaper: wallpaper,
          index: index,
          onTap: () {
            if (wallpaper.isLive) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WallpaperPreviewScreen(
                    wallpaper: wallpaper,
                    wallpapers: items,
                    initialIndex: index,
                  ),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaticPreviewScreen(
                    wallpaper: wallpaper,
                    wallpapers: items,
                    initialIndex: index,
                  ),
                ),
              );
            }
          },
          isFavorite: favoritesProvider.isFavorite(wallpaper),
          onFavoriteToggle: () => favoritesProvider.toggleFavorite(wallpaper),
        );
      },
    );
  }
}
