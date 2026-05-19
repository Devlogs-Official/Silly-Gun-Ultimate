import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:silly_gun_ultimate/screens/static_wallpapers/static_preview_screen.dart';

import '../models/wallpaper_model.dart';
import '../providers/favorites_provider.dart';
import '../widgets/app_colors.dart';
import '../widgets/wallpaper_grid_item.dart';
import 'live_wallpapers/wallpaper_preview_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;
    final staticFavorites = favorites
        .where((item) => !item.isLive)
        .toList(growable: false);
    final liveFavorites = favorites
        .where((item) => item.isLive)
        .toList(growable: false);

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1B1F27) : Colors.white;
    final Color borderColor = isDark
        ? const Color(0xFF272C36)
        : AppColors.border;
    final Color titleColor = Colors.white;
    final Color tabIndicatorColor = isDark
        ? const Color(0xFF2A3550)
        : AppColors.primary;
    final Color tabUnselected = isDark
        ? const Color(0xFF8A93A6)
        : AppColors.textSecondary;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text("Favorites Wallpapers"),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8,),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  indicator: BoxDecoration(
                    color: tabIndicatorColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  labelColor: titleColor,
                  unselectedLabelColor: tabUnselected,
                  dividerColor: Colors.transparent,
                  tabs: const <Tab>[
                    Tab(text: 'Static'),
                    Tab(text: 'Live'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _FavoritesGrid(
                      items: staticFavorites,
                      // emptyTitle: 'No static favorites yet',
                      // emptySubtitle: 'Save regular wallpapers to see them here.',
                    ),
                    _FavoritesGrid(
                      items: liveFavorites,
                      // emptyTitle: 'No live favorites yet',
                      // emptySubtitle: 'Save live wallpapers to see them here.',
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final FavoritesProvider favoritesProvider = context
        .watch<FavoritesProvider>();
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No favorites yet',
          style: TextStyle(
            color: Color(0xFFFF7597),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return MasonryGridView.count(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
              return;
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
            // Navigator.of(context).push(
            // MaterialPageRoute<void>(
            //   builder: (_) => StaticWallpaperDetailScreen(
            //     wallpaper: wallpaper,
            //   ),
            // ),
            // );
          },
          isFavorite: favoritesProvider.isFavorite(wallpaper),
          onFavoriteToggle: () {
            favoritesProvider.toggleFavorite(wallpaper);
          },
        );
      },
    );
  }
}
