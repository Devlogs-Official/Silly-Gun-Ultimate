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
import 'services/wallpaper_cache_service.dart';
import 'widgets/app_snackbar.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ErrorHandler.initialize();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,

          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
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

      runApp(
        SillyGunWallpapersApp(
          cacheService: cacheService,
          connectivityService: connectivityService,
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
  });

  final WallpaperCacheService cacheService;
  final ConnectivityService connectivityService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => connectivityService,
        ),
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
        title: 'Live Wallpapers',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: 'BricolageGrotesque',
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF7597),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFFF7597),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7597),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
