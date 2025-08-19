import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'utils/navigation_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/screens/login_screen.dart';

import 'di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  setupServiceLocator();

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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2196F3), // Material Blue
              brightness: Brightness.light,
            ),
            cardTheme: const CardThemeData(
              elevation: 8,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2196F3),
              brightness: Brightness.dark,
            ),
            cardTheme: const CardThemeData(
              elevation: 8,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
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
