import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'di/service_locator.dart';
import 'providers/user_provider.dart';
import 'providers/practice_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/drill_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/navigation_service.dart';
import 'ui/theme/app_theme.dart';
import 'models/practice_session.dart';
import 'models/challenge.dart';
import 'models/drill_group.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';

import 'ui/screens/splash_screen.dart';
import 'ui/screens/main_navigation_screen.dart';
import 'ui/screens/practice/practice_details_screen.dart';
import 'ui/screens/practice/create_practice_screen.dart';
import 'ui/screens/practice/drill_groups_screen.dart';
import 'ui/screens/practice/drill_list_screen.dart';
import 'ui/screens/practice/create_drill_group_screen.dart';
import 'ui/screens/practice/practice_history_screen.dart';
import 'ui/screens/challenge/challenge_details_screen.dart';
import 'ui/screens/challenge/create_challenge_screen.dart';
import 'ui/screens/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator
  setupServiceLocator();

  runApp(const BowlsAceApp());
}

class BowlsAceApp extends StatelessWidget {
  const BowlsAceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => DrillProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
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
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/dashboard': (context) => const MainNavigationScreen(),
              '/practice': (context) =>
                  const MainNavigationScreen(selectedIndex: 1),
              '/practice/new': (context) => const CreatePracticeScreen(),
              '/practice/history': (context) => const PracticeHistoryScreen(),
              '/challenges': (context) =>
                  const MainNavigationScreen(selectedIndex: 2),
              '/profile': (context) =>
                  const MainNavigationScreen(selectedIndex: 3),
              '/drill-group/new': (context) => const CreateDrillGroupScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/practice/details') {
                final session = settings.arguments as Session;
                return MaterialPageRoute(
                  builder: (context) => PracticeDetailsScreen(session: session),
                );
              }
              if (settings.name == '/drill-group/details') {
                final drillGroup = settings.arguments as DrillGroup;
                return MaterialPageRoute(
                  builder: (context) => DrillListScreen(drillGroup: drillGroup),
                );
              }
              if (settings.name == '/challenge/details') {
                final challenge = settings.arguments as Challenge;
                return MaterialPageRoute(
                  builder: (context) =>
                      ChallengeDetailsScreen(challenge: challenge),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
