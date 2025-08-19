import 'dart:convert';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../utils/secure_storage.dart';

class UserRepository {
  final SecureStorage _secureStorage;
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'access_token';

  UserRepository(this._secureStorage);

  Future<void> saveUser(User user, String? accessToken) async {
    developer.log(
      'Saving user data',
      name: 'UserRepository',
      error: {'user': user.toJson(), 'hasToken': accessToken != null},
    );

    try {
      final userJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userKey, value: userJson);

      developer.log(
        'User data saved successfully',
        name: 'UserRepository',
        error: {'userJson': userJson},
      );

      if (accessToken != null) {
        await _secureStorage.write(key: _tokenKey, value: accessToken);
        developer.log(
          'Access token saved successfully',
          name: 'UserRepository',
        );
      }
    } catch (e) {
      developer.log(
        'Error saving user data',
        name: 'UserRepository',
        error: e.toString(),
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    developer.log('Getting current user data', name: 'UserRepository');

    try {
      final userJson = await _secureStorage.read(key: _userKey);

      if (userJson == null) {
        developer.log('No user data found in storage', name: 'UserRepository');
        return null;
      }

      developer.log(
        'Parsing stored user data',
        name: 'UserRepository',
        error: {'userJson': userJson},
      );

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(userMap);

      developer.log(
        'User data retrieved successfully',
        name: 'UserRepository',
        error: {'user': user.toJson()},
      );

      return user;
    } catch (e) {
      developer.log(
        'Error accessing or parsing user data',
        name: 'UserRepository',
        error: e.toString(),
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      developer.log(
        'Retrieved access token',
        name: 'UserRepository',
        error: {'hasToken': token != null},
      );
      return token;
    } catch (e) {
      developer.log(
        'Error retrieving access token',
        name: 'UserRepository',
        error: e.toString(),
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }

  Future<void> clearUser() async {
    try {
      await _secureStorage.delete(key: _userKey);
      await _secureStorage.delete(key: _tokenKey);
      developer.log('User data cleared successfully', name: 'UserRepository');
    } catch (e) {
      developer.log(
        'Error clearing user data',
        name: 'UserRepository',
        error: e.toString(),
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}
