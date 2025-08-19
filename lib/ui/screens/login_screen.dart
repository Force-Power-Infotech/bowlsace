import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../utils/navigation_service.dart';
import '../../../api/api_client.dart';
import '../../../api/services/auth_api.dart';
import '../../../models/user.dart';
import '../../../repositories/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AuthApi _authApi;
  late final UserRepository _userRepository;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _showOtpField = false;
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _authApi = GetIt.I<AuthApi>();
    _userRepository = GetIt.I<UserRepository>();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  String? _error;

  void _verifyPhone() async {
    developer.log(
      'Attempting to request OTP',
      name: 'LoginScreen',
      error: {'phone_number': _phoneController.text},
    );

    if (_phoneController.text.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      developer.log(
        'OTP request failed - empty phone number',
        name: 'LoginScreen',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authApi.requestOtp(_phoneController.text);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showOtpField = true;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to send OTP. Please try again.';
        });
      }
    }
  }

  void _verifyOtp() async {
    developer.log(
      'Attempting to verify OTP',
      name: 'LoginScreen',
      error: {
        'phone_number': _phoneController.text,
        'otp_length': _otpController.text.length,
      },
    );

    if (_otpController.text.isEmpty) {
      setState(() => _error = 'Please enter the OTP');
      developer.log(
        'OTP verification failed - empty OTP code',
        name: 'LoginScreen',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _authApi.verifyOtp(
        _phoneController.text,
        _otpController.text,
      );

      if (response['success'] == true) {
        developer.log(
          'OTP verification successful - processing response',
          name: 'LoginScreen',
          error: response,
        );

        final user = User.fromJson(response['user']);
        developer.log(
          'User object created',
          name: 'LoginScreen',
          error: user.toJson(),
        );

        try {
          await _userRepository.saveUser(user, response['access_token']);
          developer.log('User data saved successfully', name: 'LoginScreen');

          // Verify the data was saved by reading it back
          final savedUser = await _userRepository.getCurrentUser();
          final savedToken = await _userRepository.getAccessToken();

          developer.log(
            'Verifying saved data',
            name: 'LoginScreen',
            error: {
              'user_saved': savedUser != null,
              'token_saved': savedToken != null,
              'saved_user_data': savedUser?.toJson(),
            },
          );

          if (savedUser == null) {
            throw Exception('Failed to verify saved user data');
          }
        } catch (e) {
          developer.log(
            'Error saving user data',
            name: 'LoginScreen',
            error: e.toString(),
          );
          setState(() {
            _isLoading = false;
            _error = 'Failed to save user data. Please try again.';
          });
          return;
        }

        developer.log(
          'User successfully authenticated',
          name: 'LoginScreen',
          error: {
            'user_id': user.id,
            'is_new_user': response['is_new_user'],
            'has_token': response['access_token'] != null,
          },
        );

        GetIt.I<NavigationService>().navigateToAndClear('/dashboard');
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Verification failed. Please try again.';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to verify OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ==== Gradient base ====
          const _NeonGradientBackground(),

          // ==== Animated abstract blobs ====
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Stack(
              children: [
                _GlowBlob(
                  size: 280,
                  top: lerpDouble(-40, 10, _bgAnim.value)!,
                  left: lerpDouble(-30, 20, _bgAnim.value)!,
                  startColor: const Color(0xFF6EE7F9).withOpacity(0.30),
                  endColor: const Color(0xFF22D3EE).withOpacity(0.16),
                ),
                _GlowBlob(
                  size: 360,
                  bottom: lerpDouble(-60, 0, _bgAnim.value)!,
                  right: lerpDouble(-20, 30, _bgAnim.value)!,
                  startColor: const Color(0xFF34D399).withOpacity(0.28),
                  endColor: const Color(0xFF22C55E).withOpacity(0.12),
                ),
                _GlowBlob(
                  size: 220,
                  top: lerpDouble(120, 80, _bgAnim.value)!,
                  right: lerpDouble(100, 60, _bgAnim.value)!,
                  startColor: const Color(0xFFA78BFA).withOpacity(0.25),
                  endColor: const Color(0xFF8B5CF6).withOpacity(0.10),
                ),
              ],
            ),
          ),

          // ==== Content ====
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final cardWidth = isNarrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth * 0.72).clamp(420.0, 540.0);

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardWidth),
                      child: _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo + title
                            Row(
                              children: [
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF22D3EE),
                                        Color(0xFF34D399),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.sports_cricket,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BowlsAce',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                              color: Colors.white,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fast. Sleek. Locked-in.',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.78,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),
                            Text(
                              _showOtpField
                                  ? 'Verify & jump back in'
                                  : 'Sign in to continue',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Phone
                            _BlinkField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'Enter your phone number',
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                            ),

                            // OTP (animated reveal)
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  _BlinkField(
                                    controller: _otpController,
                                    label: 'One-Time Password',
                                    hint: '6-digit code',
                                    icon: Icons.lock_rounded,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          // TODO: Resend OTP
                                        },
                                        child: const Text('Resend OTP'),
                                      ),
                                      Text(
                                        'Auto-read enabled',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.65,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              crossFadeState: _showOtpField
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                              sizeCurve: Curves.easeOutCubic,
                            ),

                            const SizedBox(height: 20),

                            // Error message
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            // CTA
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF34D399),
                                            ),
                                      ),
                                    )
                                  : _PrimaryButton(
                                      onPressed: _showOtpField
                                          ? _verifyOtp
                                          : _verifyPhone,
                                      label: _showOtpField
                                          ? 'Verify & Continue'
                                          : 'Get OTP',
                                    ),
                            ),

                            const SizedBox(height: 14),
                            // Subtle terms
                            Center(
                              child: Text(
                                'By continuing, you agree to our Terms & Privacy Policy',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.58),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Background gradient layer
class _NeonGradientBackground extends StatelessWidget {
  const _NeonGradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.9, -1.0),
          end: Alignment(0.9, 1.0),
          colors: [
            Color(0xFF0F172A), // slate-900
            Color(0xFF0B1222),
            Color(0xFF0A0F1C),
          ],
        ),
      ),
    );
  }
}

/// Soft glowing circle “blob”
class _GlowBlob extends StatelessWidget {
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color startColor;
  final Color endColor;

  const _GlowBlob({
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.startColor,
    required this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [startColor, endColor, Colors.transparent],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Frosted glass card container
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Minimal, premium input field
class _BlinkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final int? maxLength;

  const _BlinkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.autofillHints,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18), width: 1),
    );

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF34D399),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.85)),
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.86),
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: baseBorder,
        border: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFF34D399), width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }
}

/// Primary CTA with neon sweep
class _PrimaryButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const _PrimaryButton({required this.onPressed, required this.label});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, -1),
              end: Alignment(1 - t * 2, 1),
              colors: const [
                Color(0xFF22D3EE),
                Color(0xFF34D399),
                Color(0xFF22D3EE),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22D3EE).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            child: Text(widget.label),
          ),
        );
      },
    );
  }
}
