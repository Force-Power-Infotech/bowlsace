import 'package:flutter/material.dart';
import '../../../di/service_locator.dart';
import '../../../repositories/auth_repository.dart';
import '../../../api/api_error_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _verificationCode;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhoneVerificationStep = false;

  final AuthRepository _authRepository = getIt<AuthRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authRepository.requestOtp(_phoneController.text);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _isPhoneVerificationStep = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleError(e);
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
    if (!_formKey.currentState!.validate()) return;
    if (_verificationCode == null || _verificationCode!.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code';
      });
      return;
    }

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
        // Navigate to dashboard after successful verification
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Invalid verification code. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleError(e);
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _verificationCode;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhoneVerificationStep = false;

  final AuthRepository _authRepository = getIt<AuthRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authRepository.requestOtp(_phoneController.text);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _isPhoneVerificationStep = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleError(e);
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
    if (!_formKey.currentState!.validate()) return;
    if (_verificationCode == null || _verificationCode!.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code';
      });
      return;
    }

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
        // Navigate to dashboard after successful verification
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Invalid verification code. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleError(e);
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _verificationCode;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhoneVerificationStep = false;

  final AuthRepository _authRepository = getIt<AuthRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
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
      await _authRepository.requestOtp(_phoneController.text);

      if (!mounted) return;
      setState(() {
        _isPhoneVerificationStep = true;
        _isLoading = false;
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
        // For now, just navigate to dashboard after successful verification
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Invalid verification code. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleError(e);
      setState(() {
        _errorMessage = 'Failed to verify OTP. Please try again.';
        _isLoading = false;
      });
    }
        context,
      ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } catch (e) {
      _errorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPhoneVerificationStep ? 'Verify Phone' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message if registration fails
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

                const SizedBox(height: 16),

                if (!_isPhoneVerificationStep) ...[
                  // Registration form fields
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
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
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
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

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name (Optional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name (Optional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ] else ...[
                  // OTP verification fields
                  Text(
                    'We sent a verification code to ${_phoneController.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      prefixIcon: Icon(Icons.lock_outline),
                      hintText: 'Enter the 6-digit code',
                    ),
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

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _isLoading ? null : _requestOtp,
                    child: const Text('Resend Code'),
                  ),
                ],

                const SizedBox(height: 24),

                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _isPhoneVerificationStep
                              ? 'VERIFY & REGISTER'
                              : 'CONTINUE',
                        ),
                ),
                const SizedBox(height: 16),

                // Login link
                TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
