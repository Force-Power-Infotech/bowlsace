import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../utils/secure_storage.dart';
import './api_config.dart';
import 'dart:developer' as developer;

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

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _secureStorage.read(key: 'access_token');
    return _cachedToken;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: 'access_token');
  }
}

class ApiClient {
  final String baseUrl = 'https://ledboard.forcempower.com:8443/api/v1';
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
        return true;
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
        final error = json.decode(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          message: error['detail'] ?? 'API request failed',
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
}
