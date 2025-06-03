import 'package:http/http.dart' as http;
import '../api_client.dart';

class AuthInterceptor {
  final TokenManager _tokenManager;

  AuthInterceptor(this._tokenManager);

  Future<http.Request> interceptRequest(http.Request request) async {
    final token = await _tokenManager.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }

  Future<http.Response> interceptResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Handle token expiration
      _tokenManager.clearToken();
      // This would be handled by the API client's error handler
    }
    return response;
  }
}
