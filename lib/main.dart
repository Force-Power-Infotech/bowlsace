import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
        final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
          titleLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );

        // Light theme
        const lightColorScheme = ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF1E6FD9),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD7E3FF),
          onPrimaryContainer: Color(0xFF001B3D),
          secondary: Color(0xFF8A44F7),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFECDCFF),
          onSecondaryContainer: Color(0xFF22005D),
          tertiary: Color(0xFF00A896),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFB2DFDA),
          onTertiaryContainer: Color(0xFF002A26),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),
          background: Color(0xFFF8F9FD),
          onBackground: Color(0xFF1A1C1E),
          surface: Color(0xFFFCFCFF),
          onSurface: Color(0xFF1A1C1E),
          outline: Color(0xFF73777F),
          outlineVariant: Color(0xFFC3C7CF),
          surfaceVariant: Color(0xFFE0E2EC),
          onSurfaceVariant: Color(0xFF43474E),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
        );

        // Dark theme
        const darkColorScheme = ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF4D92F3),
          onPrimary: Color(0xFF002F65),
          primaryContainer: Color(0xFF004892),
          onPrimaryContainer: Color(0xFFD1E4FF),
          secondary: Color(0xFFBCB8FF),
          onSecondary: Color(0xFF3A0096),
          secondaryContainer: Color(0xFF552CAA),
          onSecondaryContainer: Color(0xFFE8DDFF),
          tertiary: Color(0xFF65D9C7),
          onTertiary: Color(0xFF00423B),
          tertiaryContainer: Color(0xFF00615A),
          onTertiaryContainer: Color(0xFF6FF7E7),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          background: Color(0xFF1A1C1E),
          onBackground: Color(0xFFE2E2E6),
          surface: Color(0xFF121316),
          onSurface: Color(0xFFE2E2E6),
          outline: Color(0xFF8D9199),
          outlineVariant: Color(0xFF43474E),
          surfaceVariant: Color(0xFF43474E),
          onSurfaceVariant: Color(0xFFC3C7CF),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
        );

        return MaterialApp(
          title: 'BowlsAce',
          navigatorKey: getIt<NavigationService>().navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            textTheme: textTheme,
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: lightColorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: lightColorScheme.outline.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: lightColorScheme.outline.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: lightColorScheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            scaffoldBackgroundColor: lightColorScheme.background,
            dividerTheme: DividerThemeData(
              color: lightColorScheme.outlineVariant.withOpacity(0.2),
              thickness: 1,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: lightColorScheme.surface,
              selectedItemColor: lightColorScheme.primary,
              unselectedItemColor: lightColorScheme.onSurfaceVariant,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: lightColorScheme.primary,
              unselectedLabelColor: lightColorScheme.onSurfaceVariant,
              indicatorColor: lightColorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            textTheme: textTheme,
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: darkColorScheme.surfaceVariant.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: darkColorScheme.outline.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: darkColorScheme.outline.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: darkColorScheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            scaffoldBackgroundColor: darkColorScheme.background,
            dividerTheme: DividerThemeData(
              color: darkColorScheme.outlineVariant.withOpacity(0.2),
              thickness: 1,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: darkColorScheme.surface,
              selectedItemColor: darkColorScheme.primary,
              unselectedItemColor: darkColorScheme.onSurfaceVariant,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: darkColorScheme.primary,
              unselectedLabelColor: darkColorScheme.onSurfaceVariant,
              indicatorColor: darkColorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
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
