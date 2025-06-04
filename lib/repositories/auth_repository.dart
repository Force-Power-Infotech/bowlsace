import 'dart:convert';
import 'dart:developer' as developer;
import '../api/services/auth_api.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../utils/secure_storage.dart';

class AuthRepository {
  final AuthApi _authApi;
  final SecureStorage _secureStorage;
  bool _isAuthenticated = false;
  User? _currentUser;

  AuthRepository(this._authApi, this._secureStorage);

  // Check for persistent login and attempt auto-login
  Future<bool> attemptAutoLogin() async {
    try {
      // Check if we have stored phone number
      final phoneNumber = await _secureStorage.read(key: 'phone_number');
      final storedUserData = await _secureStorage.read(key: 'user_data');
      final lastLoginStr = await _secureStorage.read(key: 'last_login');

      developer.log('Checking stored credentials - Phone: $phoneNumber, User data exists: ${storedUserData != null}');

      if (phoneNumber == null) {
        developer.log('No phone number found in storage');
        return false;
      }

      // Check if the session is too old (e.g., older than 30 days)
      if (lastLoginStr != null) {
        final lastLogin = DateTime.parse(lastLoginStr);
        final now = DateTime.now();
        if (now.difference(lastLogin).inDays > 30) {
          developer.log('Session expired due to age');
          await _clearAuthData();
          return false;
        }
      }

      // Try to load stored user data
      if (storedUserData != null) {
        try {
          _currentUser = User.fromJson(json.decode(storedUserData));
          _isAuthenticated = true;
          developer.log('Successfully loaded stored user data');
        } catch (e) {
          developer.log('Failed to parse stored user data: $e');
          await _clearAuthData();
          return false;
        }
      }

      // Try to get fresh user data
      try {
        final userData = await _authApi.getCurrentUser();
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        developer.log('Successfully fetched fresh user data');

        // Update stored user data
        await _secureStorage.write(
          key: 'user_data',
          value: json.encode(userData),
        );

        return true;
      } catch (e) {
        developer.log('Error fetching fresh user data: $e');
        // If we have valid stored data, we can still proceed
        if (_isAuthenticated && _currentUser != null) {
          developer.log('Using stored user data instead');
          return true;
        }
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      developer.log('Auto-login failed: $e');
      await _clearAuthData();
      return false;
    }
  }

  Future<void> _clearAuthData() async {
    developer.log('Clearing all auth data');
    await _secureStorage.delete(key: 'phone_number');
    await _secureStorage.delete(key: 'user_data');
    await _secureStorage.delete(key: 'last_login');
    _isAuthenticated = false;
    _currentUser = null;
  }

  Future<void> logout() async {
    developer.log('Logging out user');
    await _clearAuthData();
  }

  Future<bool> isLoggedIn() async {
    if (_isAuthenticated && _currentUser != null) return true;
    return await attemptAutoLogin();
  }

  Future<bool> requestOtp(String phoneNumber) async {
    try {
      await _secureStorage.write(key: 'phone_number', value: phoneNumber);
      final response = await _authApi.requestOtp(phoneNumber);
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _authApi.verifyOtp(phoneNumber, otp);
      if (response['success'] == true) {
        _isAuthenticated = true;

        // Store phone number as authentication credential
        developer.log('Storing phone number for authentication: $phoneNumber');
        await _secureStorage.write(key: 'phone_number', value: phoneNumber);

        // Store user data if available
        if (response['user_data'] != null) {
          final userData = response['user_data'];
          _currentUser = User.fromJson(userData);
          developer.log('Storing user data: ${json.encode(userData)}');

          // Store user data
          await _secureStorage.write(
            key: 'user_data',
            value: json.encode(userData),
          );

          // Store last login timestamp
          await _secureStorage.write(
            key: 'last_login',
            value: DateTime.now().toIso8601String(),
          );
        }
      }
      return response;
    } catch (e) {
      developer.log('Error during OTP verification: $e');
      await _clearAuthData();
      rethrow;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      if (!_isAuthenticated) {
        throw Exception('User not authenticated');
      }
      final userData = await _authApi.getCurrentUser();
      _currentUser = User.fromJson(userData);
      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      if (!_isAuthenticated) {
        throw Exception('User not authenticated');
      }
      final userData = await _authApi.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
      );
      _currentUser = User.fromJson(userData);
      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUser({
    required String phoneNumber,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    final data = {
      'phone_number': phoneNumber,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    };

    await _authApi.createUser(data);
    _isAuthenticated = true;
  }

  User? get currentUser => _currentUser;
}
