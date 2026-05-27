import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/app_snackbar.dart';
import 'widgets/app_typography.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ErrorHandler.initialize();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.ink,
          systemNavigationBarIconBrightness: Brightness.light,
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
    },
    ErrorHandler.handleZoneError,
  );
}

class SillyGunWallpapersApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => connectivityService,
        ),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider(
          create: (_) => WallpaperProvider(cacheService: cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider()..loadFavorites(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: ErrorHandler.navigatorKey,
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Silly Smile Gun Wallpaper',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.ink,
          canvasColor: AppColors.ink,
          textTheme: AppText.textTheme(),
          colorScheme: const ColorScheme.dark(
            brightness: Brightness.dark,
            primary: AppColors.crimson,
            onPrimary: AppColors.bone,
            secondary: AppColors.emberGlow,
            onSecondary: AppColors.ink,
            surface: AppColors.obsidian,
            onSurface: AppColors.bone,
            surfaceContainerHighest: AppColors.graphite,
            outline: AppColors.hairline,
            error: AppColors.crimsonDeep,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.bone,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: AppText.headline(size: 17, weight: FontWeight.w800),
            iconTheme: const IconThemeData(color: AppColors.bone),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.obsidian,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.hairline),
            ),
            titleTextStyle: AppText.headline(size: 18),
            contentTextStyle: AppText.body(),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: AppColors.bone,
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
              foregroundColor: AppColors.bone,
              side: const BorderSide(color: AppColors.hairline),
              minimumSize: const Size(0, 52),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              textStyle: AppText.button(),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.bone,
              textStyle: AppText.button(),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColors.crimson,
            linearTrackColor: AppColors.graphite,
            circularTrackColor: AppColors.graphite,
          ),
          drawerTheme: const DrawerThemeData(
            backgroundColor: AppColors.ink,
            scrimColor: Color(0xCC000000),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.hairline,
            thickness: 1,
            space: 1,
          ),
          iconTheme: const IconThemeData(color: AppColors.bone),
          listTileTheme: const ListTileThemeData(
            iconColor: AppColors.bone,
            textColor: AppColors.bone,
          ),
          splashFactory: InkSparkle.splashFactory,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
