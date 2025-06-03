import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';
import './api_config.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class TokenManager {
  final SecureStorage _secureStorage = SecureStorage();
  String? _cachedToken;

  // Get token, first from cache then from storage
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _secureStorage.read(key: 'access_token');
    return _cachedToken;
  }

  // Store new token
  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: 'access_token', value: token);
  }

  // Clear token on logout
  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: 'access_token');
  }

  // Check if token is expired
  bool isTokenExpired() {
    if (_cachedToken == null) return true;
    try {
      final decodedToken = jwt_decode(_cachedToken!);
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(
        decodedToken['exp'] * 1000,
      );
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      return true;
    }
  }

  // Placeholder for jwt_decode function
  // In a real implementation, you would use the jwt_decoder package
  Map<String, dynamic> jwt_decode(String token) {
    // This is a simplified placeholder. In a real implementation,
    // you would use the jwt_decoder package's JwtDecoder.decode method
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    final map = json.decode(resp);

    return map;
  }
}

class ApiClient {
  final http.Client _httpClient = http.Client();
  final TokenManager _tokenManager = TokenManager();
  final String baseUrl = ApiConfig.baseUrl;

  void _logApiCall(
    String method,
    String endpoint,
    dynamic data,
    dynamic response, [
    Error? error,
  ]) {
    developer.log(
      '🌐 API $method: $endpoint\n'
      '📤 Request: ${jsonEncode(data)}\n'
      '📥 Response: ${response != null ? jsonEncode(response) : "null"}'
      '${error != null ? "\n❌ Error: $error" : ""}',
      name: 'API',
    );
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      final responseData = _handleResponse(response);
      _logApiCall('GET', endpoint, null, responseData);
      return responseData;
    } catch (e) {
      _logApiCall(
        'GET',
        endpoint,
        null,
        null,
        e is Error ? e as Error : Error(),
      );
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final response = await _httpClient.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      final responseData = _handleResponse(response);
      _logApiCall('POST', endpoint, data, responseData);
      return responseData;
    } catch (e) {
      _logApiCall(
        'POST',
        endpoint,
        data,
        null,
        e is Error ? e as Error : Error(),
      );
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final response = await _httpClient.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      final responseData = _handleResponse(response);
      _logApiCall('PUT', endpoint, data, responseData);
      return responseData;
    } catch (e) {
      _logApiCall(
        'PUT',
        endpoint,
        data,
        null,
        e is Error ? e as Error : Error(),
      );
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await _httpClient.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      final responseData = _handleResponse(response);
      _logApiCall('DELETE', endpoint, null, responseData);
      return responseData;
    } catch (e) {
      _logApiCall(
        'DELETE',
        endpoint,
        null,
        null,
        e is Error ? e as Error : Error(),
      );
      if (e is http.ClientException) {
        throw NetworkException('Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Handle unauthorized - clear token and redirect to login
      _tokenManager.clearToken();
      throw UnauthorizedException('Session expired');
    } else {
      // Handle other errors
      try {
        final error = json.decode(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          message: error['detail'] ?? 'Unknown error',
        );
      } catch (e) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Error processing request',
        );
      }
    }
  }
}
