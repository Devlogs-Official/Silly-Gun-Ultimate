import 'dart:async';

import 'package:flutter/material.dart';
import 'package:silly_gun_ultimate/screens/main_navigation_screen.dart';
import 'package:video_player/video_player.dart';

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

  late final VideoPlayerController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _titleSlide;

  Timer? _navigationTimer;
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

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    _navigationTimer = Timer(_splashDuration, _navigate);
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navigationTimer?.cancel();
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

  @override
  void dispose() {
    _navigationTimer?.cancel();
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
        onTap: _navigate,
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
                                    color: AppColors.bone.withValues(alpha: 0.75),
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
                            style: AppText.mono(
                              size: 10,
                              color: AppColors.ash,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'TAP TO ENTER',
                        style: AppText.mono(
                          size: 10,
                          color: AppColors.smoke,
                        ),
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
