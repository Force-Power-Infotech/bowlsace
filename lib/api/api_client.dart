import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
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
  final dynamic error;
  final StackTrace? stackTrace;

  NetworkException(this.message, {this.error, this.stackTrace});

  @override
  String toString() {
    return 'NetworkException: $message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStack trace:\n$stackTrace' : ''}';
  }
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
      final decodedToken = _decodeJwt(_cachedToken!);
      if (decodedToken.containsKey('exp')) {
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(
          (decodedToken['exp'] as int) * 1000,
        );
        return DateTime.now().isAfter(expirationDate);
      }
      return false;
    } catch (e) {
      return true;
    }
  }

  // Decode JWT token without external packages
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }

      String payload = parts[1];
      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final normalized = base64.normalize(payload);
      final resp = utf8.decode(base64.decode(normalized));
      return json.decode(resp) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to decode JWT token: $e');
    }
  }
}

class ApiClient {
  final String baseUrl = ApiConfig.baseUrl;
  final TokenManager _tokenManager = TokenManager();
  late final http.Client _client;

  ApiClient() {
    final clientIO = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        developer.log(
          'Accepting self-signed certificate',
          error: {
            'host': host,
            'port': port,
            'issuer': cert.issuer,
            'subject': cert.subject,
          },
        );
        return true; // Allow self-signed certificates
      };
    _client = IOClient(clientIO);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic>? body, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = Uri.parse('$baseUrl$path');
      if (queryParameters != null) {
        url = url.replace(queryParameters: queryParameters);
      }

      // Log outgoing request details
      developer.log(
        'API POST Request',
        error: {
          'url': url.toString(),
          'headers': headers,
          'body': body != null ? jsonEncode(body) : null,
        },
      );

      final response = await _client.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      // Log response details
      developer.log(
        'API Response',
        error: {
          'url': url.toString(),
          'statusCode': response.statusCode,
          'headers': response.headers,
          'body': response.body,
        },
      );

      if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized request');
      }

      if (response.statusCode >= 400) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'API request failed: ${response.body}',
        );
      }

      return json.decode(response.body);
    } catch (e, stackTrace) {
      developer.log('API Error', error: e, stackTrace: stackTrace);

      if (e is ApiException || e is UnauthorizedException) {
        rethrow;
      }

      throw NetworkException(
        'Network error occurred while making POST request to $path',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = Uri.parse('$baseUrl$path');
      if (queryParameters != null) {
        url = url.replace(queryParameters: queryParameters);
      }

      developer.log('API GET Request: $url');

      final response = await _client.get(url, headers: headers);

      developer.log('API Response Status: ${response.statusCode}');
      developer.log('API Response Body: ${response.body}');

      if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized request');
      }

      if (response.statusCode >= 400) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'API request failed: ${response.body}',
        );
      }

      return json.decode(response.body);
    } catch (e) {
      if (e is ApiException || e is UnauthorizedException) {
        rethrow;
      }
      throw NetworkException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic>? body, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = Uri.parse('$baseUrl$path');
      if (queryParameters != null) {
        url = url.replace(queryParameters: queryParameters);
      }

      developer.log('API PUT Request: $url');
      if (body != null) {
        developer.log('Body: ${jsonEncode(body)}');
      }

      final response = await _client.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      developer.log('API Response Status: ${response.statusCode}');
      developer.log('API Response Body: ${response.body}');

      if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized request');
      }

      if (response.statusCode >= 400) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'API request failed: ${response.body}',
        );
      }

      return json.decode(response.body);
    } catch (e) {
      if (e is ApiException || e is UnauthorizedException) {
        rethrow;
      }
      throw NetworkException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = Uri.parse('$baseUrl$path');
      if (queryParameters != null) {
        url = url.replace(queryParameters: queryParameters);
      }

      developer.log('API DELETE Request: $url');

      final response = await _client.delete(url, headers: headers);

      developer.log('API Response Status: ${response.statusCode}');
      developer.log('API Response Body: ${response.body}');

      if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized request');
      }

      if (response.statusCode >= 400) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'API request failed: ${response.body}',
        );
      }

      // For DELETE requests, the response might be empty
      if (response.body.isEmpty) {
        return <String, dynamic>{'success': true};
      }

      return json.decode(response.body);
    } catch (e) {
      if (e is ApiException || e is UnauthorizedException) {
        rethrow;
      }
      throw NetworkException('Network error: $e');
    }
  }
}
