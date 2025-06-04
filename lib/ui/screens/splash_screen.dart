import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../di/service_locator.dart';
import '../../repositories/auth_repository.dart';
import '../../providers/user_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
          ),
        );

    _controller.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    developer.log('Starting auth check in splash screen');

    try {
      // Show animations for at least 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      developer.log('Attempting auto-login...');
      final isLoggedIn = await _authRepository.attemptAutoLogin();
      developer.log('Auto-login result: $isLoggedIn');

      if (!mounted) {
        developer.log('Widget not mounted after auto-login check');
        return;
      }

      if (isLoggedIn) {
        developer.log('User is logged in, fetching current user data...');

        try {
          // Try to get fresh user data
          final user = await _authRepository.getCurrentUser();
          developer.log('Successfully fetched user data: ${user.toString()}');

          if (!mounted) return;

          // Update the user provider with the fresh data
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          userProvider.setUser(user);

          developer.log('Navigating to dashboard...');
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } catch (userError) {
          developer.log('Error fetching user data: $userError');

          // Even if getting fresh data fails, we can still proceed if we have cached user
          final cachedUser = _authRepository.currentUser;
          if (cachedUser != null) {
            developer.log('Using cached user data: ${cachedUser.toString()}');
            if (!mounted) return;

            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            userProvider.setUser(cachedUser);

            developer.log('Navigating to dashboard with cached data...');
            Navigator.of(context).pushReplacementNamed('/dashboard');
            return;
          }

          // If we have no user data at all, go to login
          developer.log('No cached user data available, redirecting to login');
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        developer.log('User is not logged in, redirecting to login screen');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      developer.log('Error during auth check: $e');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.8),
              AppTheme.secondaryTeal,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: size.width * 0.3,
                    height: size.width * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sports_cricket,
                      size: size.width * 0.2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Column(
                    children: [
                      Text(
                        'BowlsAce',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Perfect Your Game',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
