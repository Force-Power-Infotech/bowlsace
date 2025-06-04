import '../api/services/auth_api.dart';
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
      // Check if we have stored credentials
      final phoneNumber = await _secureStorage.read(key: 'phone_number');
      final token = await _secureStorage.read(key: 'auth_token');

      if (phoneNumber != null && token != null) {
        // Verify token by trying to get current user
        final userData = await _authApi.getCurrentUser();
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        return true;
      }
      return false;
    } catch (e) {
      // Clear any stored data if auto-login fails
      await _secureStorage.delete(key: 'phone_number');
      await _secureStorage.delete(key: 'auth_token');
      _isAuthenticated = false;
      _currentUser = null;
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    await _secureStorage.delete(key: 'phone_number');
    await _secureStorage.delete(key: 'auth_token');
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

        // Store auth data
        await _secureStorage.write(key: 'phone_number', value: phoneNumber);
        if (response['access_token'] != null) {
          await _secureStorage.write(
            key: 'auth_token',
            value: response['access_token'],
          );
        }

        // Store user data if available
        if (response['user_data'] != null) {
          _currentUser = User.fromJson(response['user_data']);
        }
      }
      return response;
    } catch (e) {
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
