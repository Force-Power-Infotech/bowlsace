import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../repositories/auth_repository.dart';
import '../../../api/api_error_handler.dart';
import '../../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;

  final AuthRepository _authRepository = getIt<AuthRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.requestOtp(_phoneNumberController.text);
      setState(() {
        _otpSent = true;
      });
    } catch (e) {
      _errorHandler.handleAuthError(e);
      setState(() {
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authRepository.verifyOtp(
        _phoneNumberController.text,
        _otpController.text,
      );

      if (response['success'] == true) {
        // Get user data from response and update provider
        try {
          // final userProvider = Provider.of<UserProvider>(
          //   context,
          //   listen: false,
          // );
          // if (response['user_data'] != null) {
          //   userProvider.setUser(response['user_data']);
          // }

          if (!mounted) return;

          // Clear navigation stack and go to dashboard
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
        } catch (e) {
          if (!mounted) return;

          // If user data handling fails, logout and show error
          await _authRepository.logout();
          setState(() {
            _errorMessage = 'Failed to process user data. Please try again.';
            _isLoading = false;
            _otpSent = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Invalid OTP. Please try again.';
          _isLoading = false;
          _otpSent = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleAuthError(e);
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).pushNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or App Title
              const Text(
                'BowlsAce',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 40),

              // Error message if login fails
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Phone number field
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Add more phone number validation if needed
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // OTP field (shown only after phone number is submitted)
              if (_otpSent)
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: Icon(Icons.lock_clock),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the OTP';
                    }
                    return null;
                  },
                ),
              if (_otpSent) const SizedBox(height: 24),

              // Request OTP / Verify OTP button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_otpSent ? _verifyOtp : _requestOtp),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_otpSent ? 'VERIFY OTP' : 'REQUEST OTP'),
              ),

              // Resend OTP button
              if (_otpSent)
                TextButton(
                  onPressed: _isLoading ? null : _requestOtp,
                  child: const Text('Resend OTP'),
                ),
              const SizedBox(height: 16),

              // Register link
              TextButton(
                onPressed: _navigateToRegister,
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
