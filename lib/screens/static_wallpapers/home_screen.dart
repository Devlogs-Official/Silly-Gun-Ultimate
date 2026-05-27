import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../models/wallpaper_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/wallpaper_provider.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_typography.dart';
import '../../widgets/no_internet_widget.dart';
import '../../widgets/retry_widget.dart';
import '../../widgets/section_label.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/wallpaper_grid_item.dart';
import '../app_drawer.dart';
import 'live_wallpaper_card.dart';
import 'static_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenLiveTab});

  final VoidCallback? onOpenLiveTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _fetchInitial();
    });
  }

  Future<void> _fetchInitial() async {
    final connectivity = context.read<ConnectivityService>();
    final provider = context.read<WallpaperProvider>();
    final hasInternet = await connectivity.refresh();
    if (!mounted) return;

    if (!hasInternet) {
      provider.restoreCachedWallpapers(isLive: false);
      if (provider.wallpapersFor(isLive: false).isEmpty) {
        AppSnackbar.internet('No internet connection.');
      }
      return;
    }

    await provider.fetchInitialWallpapers(isLive: false);
  }

  Future<void> _refreshWallpapers() async {
    final connectivity = context.read<ConnectivityService>();
    final hasInternet = await connectivity.refresh();
    if (!mounted) return;

    if (!hasInternet) {
      AppSnackbar.internet('You are offline. Showing cached wallpapers.');
      context.read<WallpaperProvider>().restoreCachedWallpapers(isLive: false);
      return;
    }
    await context.read<WallpaperProvider>().refreshWallpapers(isLive: false);
  }

  Future<void> _fetchMoreWallpapers() async {
    final provider = context.read<WallpaperProvider>();
    if (provider.isLoadingFor(isLive: false) ||
        provider.isLoadingMoreFor(isLive: false) ||
        !provider.hasMoreFor(isLive: false)) {
      return;
    }
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.hasInternet && !(await connectivity.refresh())) {
      AppSnackbar.internet('Connect to the internet to load more wallpapers.');
      return;
    }
    await provider.fetchMoreWallpapers(isLive: false);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      _fetchMoreWallpapers();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FavoritesProvider favoritesProvider =
        context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      drawer: const ModernDrawer(),
      body: SafeArea(
        bottom: false,
        child: Consumer2<WallpaperProvider, ConnectivityService>(
          builder: (context, provider, connectivity, _) {
            final wallpapers = provider.wallpapersFor(isLive: false);
            final noData = wallpapers.isEmpty;

            if (provider.isLoadingFor(isLive: false) && noData) {
              return Column(
                children: [
                  _AppBar(onOpenDrawer: () => Scaffold.of(context).openDrawer()),
                  const Expanded(child: ShimmerGrid()),
                ],
              );
            }

            if (!connectivity.hasInternet && noData) {
              return NoInternetWidget(onRetry: _fetchInitial);
            }

            final error = provider.errorMessageFor(isLive: false);
            if (error != null && noData) {
              return RetryWidget(message: error, onRetry: _fetchInitial);
            }

            if (!provider.isLoadingFor(isLive: false) && noData) {
              return _EmptyState(onRefresh: _refreshWallpapers);
            }

            return RefreshIndicator.adaptive(
              color: AppColors.crimson,
              backgroundColor: AppColors.obsidian,
              onRefresh: _refreshWallpapers,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Builder(
                      builder: (ctx) => _AppBar(
                        onOpenDrawer: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: LiveWallpaperCard(
                      onTap: () => widget.onOpenLiveTab?.call(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                    sliver: SliverToBoxAdapter(
                      child: SectionLabel(
                        eyebrow: 'STATIC DROPS',
                        headline: 'THE COLLECTION',
                        trailing: _formatCount(wallpapers.length),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                    sliver: SliverToBoxAdapter(
                      child: MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        itemCount: wallpapers.length +
                            (provider.hasMoreFor(isLive: false) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= wallpapers.length) {
                            if (provider.isLoadingMoreFor(isLive: false)) {
                              return const _BottomLoaderTile();
                            }
                            if (provider.errorMessageFor(isLive: false) != null &&
                                provider.hasMoreFor(isLive: false)) {
                              return _LoadMoreRetryTile(
                                onRetry: _fetchMoreWallpapers,
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          final WallpaperModel wallpaper = wallpapers[index];
                          return WallpaperGridItem(
                            key: ValueKey('static-${wallpaper.id}'),
                            wallpaper: wallpaper,
                            index: index,
                            isFavorite: favoritesProvider.isFavorite(wallpaper),
                            onFavoriteToggle: () =>
                                favoritesProvider.toggleFavorite(wallpaper),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StaticPreviewScreen(
                                    wallpaper: wallpaper,
                                    wallpapers: wallpapers,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatCount(int n) {
    final padded = n.toString().padLeft(2, '0');
    return '$padded WALLPAPERS';
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Row(
        children: [
          _IconChip(
            icon: Icons.menu_rounded,
            onTap: onOpenDrawer,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SILLY SMILE',
                  style: AppText.eyebrow(
                    color: AppColors.bone,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'GALLERY',
                  style: AppText.display(
                    size: 22,
                    letterSpacing: 1.8,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          _IconChip(
            icon: Icons.search_rounded,
            badged: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.onTap,
    this.badged = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool badged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.obsidian,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.bone, size: 18),
              if (badged)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomLoaderTile extends StatelessWidget {
  const _BottomLoaderTile();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 96,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _LoadMoreRetryTile extends StatelessWidget {
  const _LoadMoreRetryTile({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('RETRY'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: AppColors.crimson,
      backgroundColor: AppColors.obsidian,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.26),
          const Icon(
            Icons.image_outlined,
            color: AppColors.crimson,
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            'NO WALLPAPERS YET',
            textAlign: TextAlign.center,
            style: AppText.display(size: 24, letterSpacing: 2.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh the collection.',
            textAlign: TextAlign.center,
            style: AppText.body(),
          ),
        ],
      ),
    );
  }
}
