import '../api_client.dart';
import '../api_config.dart';
import '../../models/user.dart';

class AuthApi {
  final ApiClient _apiClient;

  AuthApi(this._apiClient);

  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    // API expects phone_number as a query parameter
    return await _apiClient.post(
      '${ApiConfig.requestOtp}?phone_number=$phoneNumber',
      {},
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    final data = {'phone_number': phoneNumber, 'otp': otp};
    final response = await _apiClient.post(ApiConfig.verifyOtp, data);
    return response;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _apiClient.get(ApiConfig.currentUser);
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
