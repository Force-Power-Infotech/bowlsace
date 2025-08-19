import 'dart:developer' as developer;
import '../api_client.dart';
import '../api_config.dart';

class AuthApi {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  AuthApi(this._apiClient) : _tokenManager = TokenManager();

  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      developer.log(
        'Requesting OTP',
        name: 'AuthApi',
        error: {'phone_number': phoneNumber},
      );

      final data = {'phone_number': phoneNumber};
      final response = await _apiClient.post(ApiConfig.requestOtp, data);

      developer.log('OTP Request Response', name: 'AuthApi', error: response);

      if (!response.containsKey('message')) {
        throw ApiException(
          statusCode: 500,
          message: 'Invalid response format from server',
        );
      }

      return response;
    } on ApiException catch (e) {
      developer.log(
        'OTP Request Error',
        name: 'AuthApi',
        error: {'status': e.statusCode, 'message': e.message},
        stackTrace: StackTrace.current,
      );

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
      developer.log(
        'Verifying OTP',
        name: 'AuthApi',
        error: {'phone_number': phoneNumber, 'otp': otp},
      );

      final data = {'phone_number': phoneNumber, 'otp': otp};
      final response = await _apiClient.post(ApiConfig.verifyOtp, data);

      developer.log(
        'OTP Verification Response',
        name: 'AuthApi',
        error: response,
      );

      if (!response.containsKey('message')) {
        throw ApiException(
          statusCode: 500,
          message: 'Invalid response format from server',
        );
      }

      return response;
    } on ApiException catch (e) {
      developer.log(
        'OTP Verification Error',
        name: 'AuthApi',
        error: {'status': e.statusCode, 'message': e.message},
        stackTrace: StackTrace.current,
      );

      if (e.statusCode == 401) {
        throw ApiException(
          statusCode: 401,
          message: 'Invalid or expired OTP code. Please request a new one.',
        );
      }
      rethrow;
    }
  }
}
