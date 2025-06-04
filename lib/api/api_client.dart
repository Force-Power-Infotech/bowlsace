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
  final SecureStorage _secureStorage = SecureStorage();
  final String baseUrl = ApiConfig.baseUrl;
  static const int maxRetries = 3;

  void _logApiCall(
    String method,
    String endpoint,
    dynamic data,
    dynamic response, [
    Object? error,
    int? attempt,
  ]) {
    final attemptStr = attempt != null ? ' (Attempt $attempt/$maxRetries)' : '';
    developer.log(
      '🌐 API $method: $endpoint$attemptStr\n'
      '📤 Request: ${data != null ? jsonEncode(data) : "null"}\n'
      '📥 Response: ${response != null ? jsonEncode(response) : "null"}'
      '${error != null ? "\n❌ Error: ${error.toString()}" : ""}',
      name: 'API',
    );
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _handleResponse(
    http.Response response,
    String method,
    String endpoint,
    dynamic data,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        final responseData = json.decode(response.body);
        _logApiCall(method, endpoint, data, responseData);
        return responseData;
      } else if (response.statusCode == 401) {
        // Handle unauthorized - clear token and redirect to login
        await _secureStorage.delete(key: 'auth_token');
        throw UnauthorizedException('Session expired. Please log in again.');
      } else {
        // Handle other errors
        Map<String, dynamic> error;
        try {
          error = json.decode(response.body);
        } catch (e) {
          error = {'detail': 'Could not parse error response'};
        }

        final message =
            error['detail'] ??
            error['message'] ??
            error['error'] ??
            'Server error: ${response.statusCode}';

        _logApiCall(
          method,
          endpoint,
          data,
          error,
          ApiException(statusCode: response.statusCode, message: message),
        );

        throw ApiException(statusCode: response.statusCode, message: message);
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Error processing response: ${e.toString()}',
      );
    }
  }

  Future<T> _withRetry<T>(
    Future<T> Function() operation,
    String method,
    String endpoint,
    dynamic data,
  ) async {
    int attempt = 1;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        final isNetworkError =
            e is http.ClientException ||
            (e is ApiException && e.statusCode >= 500);

        if (isNetworkError && attempt < maxRetries) {
          _logApiCall(method, endpoint, data, null, e, attempt);
          // Exponential backoff: 1s, 2s, 4s...
          await Future.delayed(Duration(seconds: attempt));
          attempt++;
          continue;
        }
        rethrow;
      }
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    return _withRetry(
      () async {
        final headers = await _getHeaders();
        final uri = Uri.parse(
          '$baseUrl$endpoint',
        ).replace(queryParameters: queryParameters);
        final response = await _httpClient.get(uri, headers: headers);
        return _handleResponse(response, 'GET', endpoint, queryParameters);
      },
      'GET',
      endpoint,
      queryParameters,
    );
  }

  Future<dynamic> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? queryParameters,
  }) async {
    return _withRetry(
      () async {
        final headers = await _getHeaders();
        final uri = Uri.parse(
          '$baseUrl$endpoint',
        ).replace(queryParameters: queryParameters);
        final response = await _httpClient.post(
          uri,
          headers: headers,
          body: data != null ? json.encode(data) : null,
        );
        return _handleResponse(response, 'POST', endpoint, data);
      },
      'POST',
      endpoint,
      data,
    );
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    return _withRetry(
      () async {
        final headers = await _getHeaders();
        final response = await _httpClient.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: json.encode(data),
        );
        return _handleResponse(response, 'PUT', endpoint, data);
      },
      'PUT',
      endpoint,
      data,
    );
  }

  Future<dynamic> delete(String endpoint) async {
    return _withRetry(
      () async {
        final headers = await _getHeaders();
        final response = await _httpClient.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
        );
        return _handleResponse(response, 'DELETE', endpoint, null);
      },
      'DELETE',
      endpoint,
      null,
    );
  }
}
