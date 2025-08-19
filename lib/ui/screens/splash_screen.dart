import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../utils/navigation_service.dart';
import '../../repositories/user_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final UserRepository _userRepository;
  @override
  void initState() {
    super.initState();
    _userRepository = GetIt.I<UserRepository>();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    developer.log(
      'Starting app - checking for existing user data',
      name: 'SplashScreen',
    );

    // Wait for a moment to show the splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check for existing user data
    final user = await _userRepository.getCurrentUser();

    developer.log(
      'User data check result',
      name: 'SplashScreen',
      error: {'userExists': user != null, 'userData': user?.toJson()},
    );

    if (!mounted) return;

    // Navigate based on user state
    if (user != null) {
      developer.log(
        'User data found - navigating to dashboard',
        name: 'SplashScreen',
      );
      GetIt.I<NavigationService>().navigateToAndClear('/dashboard');
    } else {
      developer.log(
        'No user data found - navigating to login',
        name: 'SplashScreen',
      );
      GetIt.I<NavigationService>().navigateToAndClear('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Opacity(opacity: value, child: child);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_cricket,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'BowlsAce',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
