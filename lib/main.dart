import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'utils/navigation_service.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/main_navigation_screen.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton(() => NavigationService());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  setupLocator();

  // Initialize other services and configurations here

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const BowlsAceApp(),
    ),
  );
}

class BowlsAceApp extends StatelessWidget {
  const BowlsAceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'BowlsAce',
          navigatorKey: getIt<NavigationService>().navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/dashboard': (context) => const MainNavigationScreen(),
            '/practice': (context) =>
                const MainNavigationScreen(selectedIndex: 1),
            '/challenges': (context) =>
                const MainNavigationScreen(selectedIndex: 2),
            '/profile': (context) =>
                const MainNavigationScreen(selectedIndex: 3),
          },
        );
      },
    );
  }
}
