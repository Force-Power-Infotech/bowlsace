import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../repositories/auth_repository.dart';
import '../../../providers/user_provider.dart';
import '../../../api/api_error_handler.dart';
import '../../../di/service_locator.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthRepository _authRepository = getIt<AuthRepository>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    // The phone number will be set from route arguments in build method
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
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
        _phoneNumber,
        _otpController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Get user data from response
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (response['user_data'] != null) {
          userProvider.setUser(response['user_data']);
        }

        // Navigate to dashboard
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        setState(() {
          _errorMessage =
              response['message'] ??
              'Invalid verification code. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleError(e);
      setState(() {
        _errorMessage = 'Failed to verify code. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authRepository.requestOtp(_phoneNumber);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent again')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to resend code. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      _errorHandler.handleError(e);
      setState(() {
        _errorMessage = 'Failed to resend code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get phone number from route arguments
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Set phone number from args or use empty string if not provided
    _phoneNumber = args?['phoneNumber'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message if verification fails
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

            Text(
              'We sent a verification code to $_phoneNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Enter the 6-digit code',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Verify button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('VERIFY'),
            ),
            const SizedBox(height: 16),

            // Resend OTP link
            TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: const Text('Resend code'),
            ),
          ],
        ),
      ),
    );
  }
}
