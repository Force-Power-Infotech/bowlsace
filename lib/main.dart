import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'di/service_locator.dart';
import 'providers/user_provider.dart';
import 'providers/practice_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/drill_provider.dart';
import 'utils/navigation_service.dart';
import 'ui/theme/app_theme.dart';
import 'models/practice_session.dart';
import 'models/challenge.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/auth/otp_verification_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/practice/practice_list_screen.dart';
import 'ui/screens/practice/practice_details_screen.dart';
import 'ui/screens/practice/create_practice_screen.dart';
import 'ui/screens/challenge/challenge_list_screen.dart';
import 'ui/screens/challenge/challenge_details_screen.dart';
import 'ui/screens/challenge/create_challenge_screen.dart';
import 'ui/screens/profile/profile_screen.dart';
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
      ],
      child: MaterialApp(
        title: 'BowlsAce',
        navigatorKey: getIt<NavigationService>().navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/otp_verification': (context) => const OtpVerificationScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/practice/list': (context) => const PracticeListScreen(),
          '/practice/new': (context) => const CreatePracticeScreen(),
          '/challenge/list': (context) => const ChallengeListScreen(),
          '/challenge/new': (context) => const CreateChallengeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/practice/details') {
            final session = settings.arguments as Session;
            return MaterialPageRoute(
              builder: (context) => PracticeDetailsScreen(session: session),
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
      ),
    );
  }
}
