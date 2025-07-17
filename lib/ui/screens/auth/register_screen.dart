import 'package:flutter/material.dart';
import '../../../di/service_locator.dart';
import '../../../repositories/auth_repository.dart';
import '../../../api/api_error_handler.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhoneVerificationStep = false;
  String? _verificationCode;

  final AuthRepository _authRepository = getIt<AuthRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPhoneVerificationStep) {
      // First step: request OTP
      await _requestOtp();
    } else {
      // Second step: verify OTP and complete registration
      if (_verificationCode == null || _verificationCode!.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter the verification code';
        });
        return;
      }

      await _verifyAndCompleteRegistration();
    }
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authRepository.requestOtp(_phoneController.text);

      if (!mounted) return;

      setState(() {
        _isPhoneVerificationStep = success;
        _isLoading = false;
        if (!success) {
          _errorMessage = 'Failed to send verification code. Please try again.';
        }
      });
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Failed to send verification code. Please check your phone number.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyAndCompleteRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authRepository.verifyOtp(
        _phoneController.text,
        _verificationCode!,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        try {
          // After OTP verification, create the user with all details
          await _authRepository.createUser(
            phoneNumber: _phoneController.text,
            email: _emailController.text,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
          );

          if (!mounted) return;

          // After successful registration, navigate to dashboard
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
        } catch (e) {
          _errorHandler.handleError(e);
          if (!mounted) return;
          setState(() {
            _errorMessage =
                'Failed to complete registration. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              response['message'] ??
              'Invalid verification code. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to verify OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  final accentColor = AppTheme.primaryGreen;
    final isDark = theme.brightness == Brightness.dark;
    InputDecoration _inputDecoration(String label, {String? hint, IconData? icon}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: accentColor) : null,
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
        labelStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isPhoneVerificationStep ? 'Verify Phone' : 'Register',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                if (!_isPhoneVerificationStep) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: _inputDecoration('Username', hint: 'Enter your username', icon: Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: _inputDecoration('First Name', hint: 'Enter your first name', icon: Icons.badge_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: _inputDecoration('Last Name (Optional)', hint: 'Enter your last name (optional)', icon: Icons.badge_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('Email', hint: 'Enter your email address', icon: Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _inputDecoration('Phone Number', hint: 'Enter your phone number', icon: Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _inputDecoration('Password', hint: 'Enter your password', icon: Icons.lock_outline),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isPhoneVerificationStep) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: _inputDecoration('Verification Code', hint: 'Enter the code sent to your phone', icon: Icons.verified_outlined),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _verificationCode = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the verification code';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    shadowColor: accentColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isPhoneVerificationStep
                              ? 'Verify and Register'
                              : 'Get Verification Code',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Already have an account? Login',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
