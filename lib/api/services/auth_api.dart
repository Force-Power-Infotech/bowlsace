import '../api_client.dart';
import '../api_config.dart';

class AuthApi {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  AuthApi(this._apiClient) : _tokenManager = TokenManager();

  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      // Send phone_number as query parameter instead of request body
      final response = await _apiClient.post(
        ApiConfig.requestOtp,
        null, // no request body needed
        queryParameters: {'phone_number': phoneNumber},
      );

      if (!response.containsKey('success')) {
        throw ApiException(
          statusCode: 500,
          message: 'Invalid response format from server',
        );
      }

      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 429) {
        throw ApiException(
          statusCode: 429,
          message: 'Too many OTP requests. Please wait before trying again.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final data = {'phone_number': phoneNumber, 'otp': otp};
      final response = await _apiClient.post(ApiConfig.verifyOtp, data);

      if (!response.containsKey('success')) {
        throw ApiException(
          statusCode: 500,
          message: 'Invalid response format from server',
        );
      }

      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw ApiException(
          statusCode: 401,
          message: 'Invalid or expired OTP code. Please request a new one.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _apiClient.get(ApiConfig.currentUser);
  }

  Future<void> updateToken(String token) async {
    await _tokenManager.setToken(token);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    final data = {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
    return await _apiClient.put(ApiConfig.updateProfile, data);
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiConfig.register, data);
    return response;
  }
}
