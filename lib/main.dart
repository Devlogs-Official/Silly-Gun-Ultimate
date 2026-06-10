import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'core/app_logger.dart';
import 'core/error_handler.dart';
import 'providers/wallpaper_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/splash_screen.dart';
import 'services/connectivity_service.dart';
import 'services/settings_service.dart';
import 'services/wallpaper_cache_service.dart';
import 'widgets/app_colors.dart';
import 'widgets/app_palette.dart';
import 'widgets/app_snackbar.dart';
import 'widgets/app_typography.dart';
import 'core/config/config_manager.dart';
import 'services/ads_service.dart';
import 'services/app_open_manager.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorHandler.initialize();
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: <String>[
          '9B9386F85AF0FC76B9DDB4A4E8622406',
        ],
      ),
    );

    final cacheService = WallpaperCacheService();
    try {
      await cacheService.init();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Hive cache initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final connectivityService = ConnectivityService();
    await connectivityService.initialize();

    final settingsService = SettingsService();
    await settingsService.load();

    runApp(
      SillyGunWallpapersApp(
        cacheService: cacheService,
        connectivityService: connectivityService,
        settingsService: settingsService,
      ),
    );
  }, ErrorHandler.handleZoneError);
}

class SillyGunWallpapersApp extends StatefulWidget {
  const SillyGunWallpapersApp({
    super.key,
    required this.cacheService,
    required this.connectivityService,
    required this.settingsService,
  });

  final WallpaperCacheService cacheService;
  final ConnectivityService connectivityService;
  final SettingsService settingsService;

  @override
  State<SillyGunWallpapersApp> createState() => _SillyGunWallpapersAppState();
}

class _SillyGunWallpapersAppState extends State<SillyGunWallpapersApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      AppOpenManager.instance.onPaused(
        isShowingFullScreenAd: AdService.isShowingFullScreenAd,
      );
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _showAppOpenOnResume();
    }
  }

  Future<void> _showAppOpenOnResume() async {
    final config = ConfigManager.config;
    final shouldShow = AppOpenManager.instance.shouldShowOnResume(
      config: config,
      isShowingFullScreenAd: AdService.isShowingFullScreenAd,
    );

    if (!shouldShow) {
      return;
    }

    if (!AdService.isAppOpenAdAvailable) {
      unawaited(AdService.loadAppOpenAd());
      return;
    }

    await AdService.showAppOpenAdAndWait(
      loadTimeout: Duration.zero,
      respectMinInterval: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => widget.connectivityService,
        ),
        ChangeNotifierProvider<SettingsService>.value(
          value: widget.settingsService,
        ),
        ChangeNotifierProvider(
          create: (_) => WallpaperProvider(cacheService: widget.cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider()..loadFavorites(),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: ErrorHandler.navigatorKey,
            scaffoldMessengerKey: AppSnackbar.messengerKey,
            debugShowCheckedModeBanner: false,
            title: 'Silly Smile Gun Wallpaper',
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: settings.themeMode.flutterMode,
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              final palette = AppPalette.of(context);
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: brightness,
                  systemNavigationBarColor: palette.ink,
                  systemNavigationBarIconBrightness:
                      brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                ),
              );
              return child ?? const SizedBox.shrink();
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final baseTextTheme = isDark
        ? AppText.darkTextTheme()
        : AppText.lightTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.ink,
      canvasColor: palette.ink,
      textTheme: baseTextTheme,
      extensions: [palette],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.crimson,
        onPrimary: const Color(0xFFF5F1E8),
        secondary: AppColors.emberGlow,
        onSecondary: palette.bone,
        surface: palette.ink,
        onSurface: palette.bone,
        surfaceContainerHighest: palette.graphite,
        outline: palette.hairline,
        error: AppColors.crimsonDeep,
        onError: const Color(0xFFF5F1E8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.ink,
        foregroundColor: palette.bone,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.headline(
          size: 17,
          weight: FontWeight.w800,
          color: palette.bone,
        ),
        iconTheme: IconThemeData(color: palette.bone),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.obsidian,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.hairline),
        ),
        titleTextStyle: AppText.headline(size: 18, color: palette.bone),
        contentTextStyle: AppText.body(color: palette.ash),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: const Color(0xFFF5F1E8),
          disabledBackgroundColor: AppColors.crimson.withValues(alpha: 0.4),
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          textStyle: AppText.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.bone,
          side: BorderSide(color: palette.hairline),
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          textStyle: AppText.button(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.bone,
          textStyle: AppText.button(),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.crimson,
        linearTrackColor: palette.graphite,
        circularTrackColor: palette.graphite,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette.ink,
        scrimColor: const Color(0xAA000000),
      ),
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: palette.bone),
      listTileTheme: ListTileThemeData(
        iconColor: palette.bone,
        textColor: palette.bone,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
