import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:silly_gun_ultimate/screens/main_navigation_screen.dart';
import 'package:video_player/video_player.dart';

import '../core/app_logger.dart';
import '../core/config/config_manager.dart';
import '../firebase_options.dart';
import '../services/ads_service.dart';
import '../services/app_open_manager.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(seconds: 3);
  static const Duration _appOpenLoadTimeout = Duration(seconds: 8);
  static const Duration _appOpenShowTimeout = Duration(seconds: 10);

  late final VideoPlayerController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _titleSlide;
  late final Future<void> _minimumSplashFuture;
  late final Future<bool> _startupFuture;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/splash/splash.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 1, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    _minimumSplashFuture = Future<void>.delayed(_splashDuration);
    _startupFuture = _initializeStartup();
    unawaited(_navigateWhenReady());
  }

  Future<bool> _initializeStartup() async {
    try {
      await _initializeFirebaseIfNeeded();
      await ConfigManager.instance.fetchAndActivateRemoteConfig();
      return AdService.loadAppOpenAd().timeout(
        _appOpenLoadTimeout,
        onTimeout: () => false,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Splash startup initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _initializeFirebaseIfNeeded() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> _navigateWhenReady() async {
    if (_navigated || !mounted) return;
    await _minimumSplashFuture;
    final bool appOpenLoaded = await _startupFuture;
    if (_navigated || !mounted) return;

    _navigated = true;
    await _showColdStartAppOpenIfReady(appOpenLoaded);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: const MainNavigationScreen(),
        ),
      ),
    );
  }

  Future<void> _showColdStartAppOpenIfReady(bool appOpenLoaded) async {
    if (!ConfigManager.config.showAppOpenOnColdStart ||
        !appOpenLoaded) {
      return;
    }

    await AdService.showAppOpenAdAndWait(loadTimeout: Duration.zero).timeout(
      _appOpenShowTimeout,
      onTimeout: () => AppOpenAdShowResult.notReady,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_navigateWhenReady()),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const ColoredBox(color: AppColors.ink),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.ink.withValues(alpha: 0.20),
                    AppColors.ink.withValues(alpha: 0.55),
                    AppColors.ink.withValues(alpha: 0.95),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),

            // Crimson edge stripe — left margin signature
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 2,
                  height: 120,
                  color: AppColors.crimson,
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 2,
                                  color: AppColors.crimson,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'COLLECTION · 2026',
                                  style: AppText.eyebrow(
                                    color: AppColors.bone.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'SILLY',
                              style: AppText.display(
                                size: 78,
                                letterSpacing: 0.5,
                                height: 0.88,
                              ),
                            ),
                            Text(
                              'SMILE',
                              style: AppText.display(
                                size: 78,
                                letterSpacing: 0.5,
                                height: 0.88,
                                color: AppColors.crimson,
                              ),
                            ),
                            Text(
                              'WALLPAPERS',
                              style: AppText.display(
                                size: 30,
                                letterSpacing: 6,
                                height: 1.0,
                                color: AppColors.bone.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: const LinearProgressIndicator(
                                minHeight: 2,
                                backgroundColor: AppColors.hairline,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.crimson,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'LOADING GALLERY',
                            style: AppText.mono(size: 10, color: AppColors.ash),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'TAP TO ENTER',
                        style: AppText.mono(size: 10, color: AppColors.smoke),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
