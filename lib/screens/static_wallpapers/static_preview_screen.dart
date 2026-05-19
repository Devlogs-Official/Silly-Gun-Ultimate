import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:silly_gun_ultimate/screens/static_wallpapers/static_full_preview.dart';

import '../../models/wallpaper_model.dart';
import '../../widgets/wallpaper_thumbnail_strip.dart';

class StaticPreviewScreen extends StatefulWidget {
  const StaticPreviewScreen({
    super.key,
    required this.wallpaper,
    required this.wallpapers,
    required this.initialIndex,
  });

  final WallpaperModel wallpaper;
  final List<WallpaperModel> wallpapers;
  final int initialIndex;

  @override
  State<StaticPreviewScreen> createState() =>
      _StaticPreviewScreenState();
}

class _StaticPreviewScreenState
    extends State<StaticPreviewScreen> {
  late final PageController _pageController;

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialIndex.clamp(
      0,
      widget.wallpapers.length - 1,
    );

    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.82,
    );
  }

  Future<void> _selectWallpaper(int index) async {
    if (index == _selectedIndex) return;

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFFB00020),
        foregroundColor: Colors.white,

        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),

        title: const Text(
          'Static Wallpapers',
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                const BouncingScrollPhysics(),

                itemCount: widget.wallpapers.length,

                onPageChanged: _onPageChanged,

                itemBuilder: (context, index) {
                  final wallpaper =
                  widget.wallpapers[index];

                  final bool active =
                      index == _selectedIndex;

                  return AnimatedScale(
                    duration: const Duration(
                      milliseconds: 260,
                    ),

                    curve: Curves.easeOutCubic,

                    scale: active ? 1 : 0.92,

                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        8,
                        28,
                        8,
                        20,
                      ),

                      child: _PreviewCard(
                        wallpaper: wallpaper,
                      ),
                    ),
                  );
                },
              ),
            ),

            WallpaperThumbnailStrip(
              wallpapers: widget.wallpapers,
              selectedIndex: _selectedIndex,
              onSelected: _selectWallpaper,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.wallpaper,
  });

  final WallpaperModel wallpaper;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'wallpaper-${wallpaper.id}',

      child: Material(
        color: Colors.transparent,

        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(34),

                child: Stack(
                  fit: StackFit.expand,

                  children: [
                    CachedNetworkImage(
                      imageUrl:
                      wallpaper.imageUrl,

                      fit: BoxFit.cover,

                      fadeInDuration:
                      const Duration(
                        milliseconds: 240,
                      ),

                      placeholder:
                          (context, url) {
                        return Container(
                          color: const Color(
                            0xFFFFE1EA,
                          ),

                          child: const Center(
                            child:
                            CircularProgressIndicator(
                              color: Color(0xFFB00020),
                            ),
                          ),
                        );
                      },

                      errorWidget:
                          (
                          context,
                          url,
                          error,
                          ) {
                        return const ColoredBox(
                          color: Color(
                            0xFFFFE6EC,
                          ),

                          child: Center(
                            child: Icon(
                              Icons
                                  .broken_image_outlined,

                              size: 42,

                              color: Color(0xFFB00020),
                            ),
                          ),
                        );
                      },
                    ),

                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient:
                          LinearGradient(
                            begin:
                            Alignment.topCenter,

                            end: Alignment
                                .bottomCenter,

                            colors: [
                              Colors.transparent,

                              Colors.black
                                  .withValues(
                                alpha: 0.12,
                              ),

                              Colors.black
                                  .withValues(
                                alpha: 0.48,
                              ),
                            ],

                            stops: const [
                              0.5,
                              0.72,
                              1,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 42,
              ),

              child: OpenContainer<void>(
                transitionType:
                ContainerTransitionType
                    .fadeThrough,

                transitionDuration:
                const Duration(
                  milliseconds: 460,
                ),

                closedElevation: 0,
                openElevation: 0,

                closedColor:
                const Color(0xFFB00020),

                openColor: Colors.white,

                closedShape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(20),
                ),

                openBuilder:
                    (context, action) =>
                    StaticFullScreenPreview(
                      wallpaper: wallpaper,
                    ),

                closedBuilder:
                    (_, openContainer) {
                  return InkWell(
                    onTap: openContainer,

                    borderRadius:
                    BorderRadius.circular(
                      34,
                    ),

                    child: const SizedBox(
                      height: 55,

                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                        children: [
                          Icon(
                            Icons
                                .fullscreen_rounded,

                            color: Colors.white,
                          ),

                          SizedBox(width: 8),

                          Text(
                            'Expand',

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),

                          SizedBox(width: 8),

                          Icon(
                            Icons
                                .chevron_right_rounded,

                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}