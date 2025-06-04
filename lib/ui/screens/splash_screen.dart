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
    // Add a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      final isLoggedIn = await _authRepository.attemptAutoLogin();

      if (isLoggedIn) {
        // Get user data and update provider
        final user = await _authRepository.getCurrentUser();
        if (!mounted) return;

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(user);

        // Navigate to dashboard
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        // Navigate to login
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // If there's any error, go to login
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
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
