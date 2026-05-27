import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:silly_gun_ultimate/screens/live_wallpapers/wallpaper_preview_screen.dart';

import '../../providers/favorites_provider.dart';
import '../../providers/wallpaper_provider.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_palette.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_typography.dart';
import '../../widgets/no_internet_widget.dart';
import '../../widgets/retry_widget.dart';
import '../../widgets/section_label.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/wallpaper_grid_item.dart';

class LiveWallpapersScreen extends StatefulWidget {
  const LiveWallpapersScreen({super.key});

  @override
  State<LiveWallpapersScreen> createState() => _LiveWallpapersScreenState();
}

class _LiveWallpapersScreenState extends State<LiveWallpapersScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchInitial();
    });
  }

  Future<void> _fetchInitial() async {
    final connectivity = context.read<ConnectivityService>();
    final provider = context.read<WallpaperProvider>();
    final hasInternet = await connectivity.refresh();
    if (!mounted) return;

    if (!hasInternet) {
      provider.restoreCachedWallpapers();
      if (provider.wallpapers.isEmpty) {
        AppSnackbar.internet('No internet connection.');
      }
      return;
    }
    await provider.fetchInitialWallpapers();
  }

  Future<void> _refreshWallpapers() async {
    final connectivity = context.read<ConnectivityService>();
    final hasInternet = await connectivity.refresh();
    if (!mounted) return;
    if (!hasInternet) {
      AppSnackbar.internet('You are offline. Showing cached wallpapers.');
      context.read<WallpaperProvider>().restoreCachedWallpapers();
      return;
    }
    await context.read<WallpaperProvider>().refreshWallpapers();
  }

  Future<void> _fetchMoreWallpapers() async {
    final provider = context.read<WallpaperProvider>();
    if (provider.isLoading || provider.isLoadingMore || !provider.hasMore) {
      return;
    }
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.hasInternet && !(await connectivity.refresh())) {
      AppSnackbar.internet('Connect to the internet to load more wallpapers.');
      return;
    }
    await provider.fetchMoreWallpapers();
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
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.ink,
      body: SafeArea(
        bottom: false,
        child: Consumer2<WallpaperProvider, ConnectivityService>(
          builder: (context, provider, connectivity, _) {
            final favorites = context.watch<FavoritesProvider>();
            final noData = provider.wallpapers.isEmpty;

            if (provider.isLoading && noData) {
              return const _BodyWithHeader(child: ShimmerGrid());
            }

            if (!connectivity.hasInternet && noData) {
              return NoInternetWidget(onRetry: _fetchInitial);
            }

            if (provider.errorMessage != null && noData) {
              return RetryWidget(
                message: provider.errorMessage!,
                onRetry: _fetchInitial,
              );
            }

            if (!provider.isLoading && noData) {
              return _EmptyState(onRefresh: _refreshWallpapers);
            }

            return RefreshIndicator.adaptive(
              color: AppColors.crimson,
              backgroundColor: palette.obsidian,
              onRefresh: _refreshWallpapers,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  if (!connectivity.hasInternet)
                    const SliverToBoxAdapter(child: _OfflineBanner()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
                    sliver: SliverToBoxAdapter(
                      child: SectionLabel(
                        eyebrow: 'LIVE FEED',
                        headline: 'MOTION',
                        trailing:
                            '${provider.wallpapers.length.toString().padLeft(2, '0')} LIVE',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
                    sliver: SliverToBoxAdapter(
                      child: MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        itemCount: provider.wallpapers.length +
                            (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= provider.wallpapers.length) {
                            return const _BottomLoader();
                          }
                          final wallpaper = provider.wallpapers[index];
                          return WallpaperGridItem(
                            key: ValueKey(wallpaper.id),
                            wallpaper: wallpaper,
                            index: index,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => WallpaperPreviewScreen(
                                    wallpaper: wallpaper,
                                    wallpapers: provider.wallpapers,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            isFavorite: favorites.isFavorite(wallpaper),
                            onFavoriteToggle: () =>
                                favorites.toggleFavorite(wallpaper),
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
}

class _BodyWithHeader extends StatelessWidget {
  const _BodyWithHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Header(),
        Expanded(child: child),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Row(
        children: [
          Container(width: 22, height: 2, color: AppColors.crimson),
          const SizedBox(width: 10),
          Text('CHANNEL · 02', style: AppText.eyebrow()),
          const Spacer(),
          Text('LIVE', style: AppText.mono(color: palette.bone)),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.crimson,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return RefreshIndicator.adaptive(
      color: AppColors.crimson,
      backgroundColor: palette.obsidian,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.26),
          const Icon(
            Icons.movie_outlined,
            color: AppColors.crimson,
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            'NOTHING LIVE YET',
            textAlign: TextAlign.center,
            style: AppText.display(
              size: 24,
              letterSpacing: 2.4,
              color: palette.bone,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh.',
            textAlign: TextAlign.center,
            style: AppText.body(color: palette.ash),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.obsidian,
        borderRadius: BorderRadius.circular(2),
        border: const Border(
          left: BorderSide(color: AppColors.crimson, width: 2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.crimson,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline · Showing cached wallpapers',
              style: AppText.body(color: palette.bone, size: 12.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
