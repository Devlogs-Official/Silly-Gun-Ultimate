import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:silly_gun_ultimate/widgets/app_colors.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

import '../providers/wallpaper_provider.dart';
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
      barrierColor: const Color(0x66000000),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) =>
      const _ExitAppDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        _handleBackPress();
      },
      child: Scaffold(
        drawer: ModernDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedIndex),
            child: _screens[_selectedIndex],
          ),
        ),
        bottomNavigationBar: StylishBottomBar(
          backgroundColor: const Color(0xFFB00020),
          option: AnimatedBarOptions(
            barAnimation: BarAnimation.fade,
            iconStyle: IconStyle.Default,
          ),
          currentIndex: _selectedIndex,
          onTap: (value) {
            if (value == _selectedIndex) return;
            setState(() => _selectedIndex = value);
          },
          items: [
            BottomBarItem(
              unSelectedColor: Colors.white70,
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              title: const Text('Home'),
              selectedColor: Colors.white,
            ),
            BottomBarItem(
              icon: const Icon(Icons.live_tv),
              selectedIcon: const Icon(Icons.live_tv),
              title: const Text('Live'),
              selectedColor: Colors.white,
              unSelectedColor: Colors.white70,
            ),
            BottomBarItem(
              icon: const Icon(Icons.favorite_border_rounded),
              selectedIcon: const Icon(Icons.favorite_rounded),
              title: const Text('Favorites'),
              selectedColor: Colors.white,
              unSelectedColor: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
class _ExitAppDialog extends StatelessWidget {
  const _ExitAppDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF4F7FD)],
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x2A1A2238),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:  Icon(
                    Icons.power_settings_new_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Exit Silly Wallpapers?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF151A24),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to close app right now?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF657089),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCCD4E4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          'Stay',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            fontFamily: 'Chillax',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
