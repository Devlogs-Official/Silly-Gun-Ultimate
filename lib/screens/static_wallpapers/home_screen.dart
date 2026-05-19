import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:silly_gun_ultimate/screens/app_drawer.dart';
import 'package:silly_gun_ultimate/screens/static_wallpapers/static_preview_screen.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/wallpaper_provider.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/no_internet_widget.dart';
import '../../widgets/retry_widget.dart';
import '../../widgets/shimmer_grid.dart';
import '../../widgets/wallpaper_grid_item.dart';
import 'live_wallpaper_card.dart';

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
    final ConnectivityService connectivity = context
        .read<ConnectivityService>();

    final WallpaperProvider provider = context.read<WallpaperProvider>();

    final bool hasInternet = await connectivity.refresh();

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
    final ConnectivityService connectivity = context
        .read<ConnectivityService>();

    final bool hasInternet = await connectivity.refresh();

    if (!mounted) return;

    if (!hasInternet) {
      AppSnackbar.internet('You are offline. Showing cached wallpapers.');

      context.read<WallpaperProvider>().restoreCachedWallpapers(isLive: false);

      return;
    }

    await context.read<WallpaperProvider>().refreshWallpapers(isLive: false);
  }

  Future<void> _fetchMoreWallpapers() async {
    final WallpaperProvider provider = context.read<WallpaperProvider>();

    if (provider.isLoadingFor(isLive: false) ||
        provider.isLoadingMoreFor(isLive: false) ||
        !provider.hasMoreFor(isLive: false)) {
      return;
    }

    final ConnectivityService connectivity = context
        .read<ConnectivityService>();

    if (!connectivity.hasInternet && !(await connectivity.refresh())) {
      AppSnackbar.internet('Connect to the internet to load more wallpapers.');

      return;
    }

    await provider.fetchMoreWallpapers(isLive: false);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final ScrollPosition position = _scrollController.position;

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
    final FavoritesProvider favoritesProvider = context
        .watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: ModernDrawer(),
      appBar: AppBar(
        title: const Text(
          'Silly Smile Wallpapers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.menu_rounded),
            );
          },
        ),
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFB00020),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Consumer2<WallpaperProvider, ConnectivityService>(
          builder: (context, provider, connectivity, _) {
            final List<WallpaperModel> wallpapers = provider.wallpapersFor(
              isLive: false,
            );

            final bool noData = wallpapers.isEmpty;

            if (provider.isLoadingFor(isLive: false) && noData) {
              return const ShimmerGrid();
            }

            if (!connectivity.hasInternet && noData) {
              return NoInternetWidget(onRetry: _fetchInitial);
            }

            final String? error = provider.errorMessageFor(isLive: false);

            if (error != null && noData) {
              return RetryWidget(message: error, onRetry: _fetchInitial);
            }

            if (!provider.isLoadingFor(isLive: false) && noData) {
              return _StaticEmptyState(onRefresh: _refreshWallpapers);
            }

            return RefreshIndicator.adaptive(
              color: Color(0xFFB00020),
              backgroundColor: Colors.white,
              onRefresh: _refreshWallpapers,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: LiveWallpaperCard(
                      onTap: () {
                        widget.onOpenLiveTab?.call();
                      },
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    sliver: SliverToBoxAdapter(
                      child: MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        itemCount:
                            wallpapers.length +
                            (provider.hasMoreFor(isLive: false) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= wallpapers.length) {
                            if (provider.isLoadingMoreFor(isLive: false)) {
                              return const _BottomLoaderTile();
                            }

                            if (provider.errorMessageFor(isLive: false) !=
                                    null &&
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
                            onFavoriteToggle: () {
                              favoritesProvider.toggleFavorite(wallpaper);
                            },
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
}

class _BottomLoaderTile extends StatelessWidget {
  const _BottomLoaderTile();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 96,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: Color(0xFFFF7597),
          ),
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
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ),
    );
  }
}

class _StaticEmptyState extends StatelessWidget {
  const _StaticEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: const Color(0xFFFF7597),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.26),
          const Icon(Icons.image_outlined, color: Color(0xFFFF7597), size: 52),
          const SizedBox(height: 16),
          Text(
            'No wallpapers found',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFFF7597),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
