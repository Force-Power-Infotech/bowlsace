// api_client.dart
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
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  NetworkException(this.message, {this.error, this.stackTrace});

  @override
  String toString() {
    return 'NetworkException: $message'
        '${error != null ? '\nError: $error' : ''}'
        '${stackTrace != null ? '\nStack trace:\n$stackTrace' : ''}';
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
  // If you already keep base URL in api_config.dart, feel free to route it from there.
  // Keeping your current constant for compatibility:
  final String baseUrl = 'https://ledboard.forcempower.com:8443/api/v1';
  final TokenManager _tokenManager = TokenManager();
  late final http.Client _client;

  // Increased timeout for slow connections
  static const Duration _timeout = Duration(seconds: 30);

  ApiClient() {
    final clientIO = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        // Only trust the expected host:port (still self-signed). Tightens security.
        final allow = host == 'ledboard.forcempower.com' && port == 8443;
        if (allow) {
          developer.log(
            'Accepting self-signed certificate',
            error: {
              'host': host,
              'port': port,
              'issuer': cert.issuer,
              'subject': cert.subject,
            },
          );
        }
        return allow;
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

  /// Parse server error bodies safely (JSON, list `detail`, plain text, empty).
  String _extractErrorMessage(int statusCode, String body) {
    try {
      final parsed = json.decode(body);

      // FastAPI common: {"detail": "..."} or {"detail": [ {...}, ... ]}
      if (parsed is Map && parsed['detail'] != null) {
        final detail = parsed['detail'];

        if (detail is String) return detail;

        if (detail is List) {
          final msgs = detail
              .map((e) {
                if (e is Map) {
                  final loc = (e['loc'] is List)
                      ? (e['loc'] as List).join('.')
                      : e['loc'];
                  final msg = e['msg'] ?? e['message'] ?? e.toString();
                  return (loc != null) ? '$loc: $msg' : '$msg';
                }
                return e.toString();
              })
              .join(' | ');
          return msgs.isNotEmpty ? msgs : 'API request failed ($statusCode)';
        }

        return detail.toString();
      }

      // Other common shapes: {"message": "..."} {"error": "..."} {"errors": ...}
      for (final k in ['message', 'error', 'errors']) {
        if (parsed is Map && parsed[k] != null) {
          return parsed[k].toString();
        }
      }

      // Default to a concise string of parsed content
      return parsed.toString();
    } catch (_) {
      final trimmed = body.trim();
      return trimmed.isNotEmpty ? trimmed : 'API request failed ($statusCode)';
    }
  }

  Uri _buildUrl(String path, {Map<String, String>? queryParameters}) {
    var url = Uri.parse('$baseUrl$path');
    if (queryParameters != null) {
      url = url.replace(queryParameters: queryParameters);
    }
    return url;
  }

  Map<String, String> _maskHeaders(Map<String, String> headers) {
    final masked = Map<String, String>.from(headers);
    if (masked.containsKey('Authorization')) {
      masked['Authorization'] = 'Bearer ***';
    }
    return masked;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = _buildUrl(path, queryParameters: queryParameters);

      developer.log(
        'API GET Request',
        error: {
          'url': url.toString(),
          'headers': _maskHeaders(headers),
          'queryParameters': queryParameters,
        },
      );

      final response = await _client
          .get(url, headers: headers)
          .timeout(_timeout);

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
        final message = _extractErrorMessage(
          response.statusCode,
          response.body,
        );
        throw ApiException(statusCode: response.statusCode, message: message);
      }

      if (response.body.isEmpty) {
        // Some APIs return 204/empty body on success
        return <String, dynamic>{};
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;

      // If the API returns a list but your callers expect a Map, wrap it.
      return <String, dynamic>{'data': decoded};
    } on SocketException catch (e, st) {
      developer.log('API Error (SocketException)', error: e, stackTrace: st);
      throw NetworkException(
        'No internet connection or host unreachable.',
        error: e,
        stackTrace: st,
      );
    } on HttpException catch (e, st) {
      developer.log('API Error (HttpException)', error: e, stackTrace: st);
      throw NetworkException(
        'HTTP error during GET $path',
        error: e,
        stackTrace: st,
      );
    } on FormatException catch (e, st) {
      developer.log('API Error (FormatException)', error: e, stackTrace: st);
      throw NetworkException(
        'Invalid response format from GET $path',
        error: e,
        stackTrace: st,
      );
    } on UnauthorizedException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e, st) {
      developer.log('API Error', error: e, stackTrace: st);
      throw NetworkException(
        'Network error occurred while making GET request to $path',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic>? body, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = await _getHeaders();
      if (extraHeaders != null && extraHeaders.isNotEmpty) {
        headers.addAll(extraHeaders);
      }
      final url = _buildUrl(path, queryParameters: queryParameters);

      developer.log(
        '🌐 API POST Request',
        error: {
          'url': url.toString(),
          'path': path,
          'headers': _maskHeaders(headers),
          'body': body != null ? json.encode(body) : null,
          'queryParameters': queryParameters,
        },
      );

      final response = await _client
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

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
        final message = _extractErrorMessage(
          response.statusCode,
          response.body,
        );
        throw ApiException(statusCode: response.statusCode, message: message);
      }

      if (response.body.isEmpty) {
        // 204 or empty response body
        return null;
      }

      return json.decode(response.body);
    } on SocketException catch (e, st) {
      developer.log('API Error (SocketException)', error: e, stackTrace: st);
      throw NetworkException(
        'No internet connection or connection interrupted.',
        error: e,
        stackTrace: st,
      );
    } on HttpException catch (e, st) {
      developer.log('API Error (HttpException)', error: e, stackTrace: st);
      final message = e.message.contains('Connection closed')
          ? 'Connection closed unexpectedly. Please try again.'
          : 'HTTP error during request.';
      throw NetworkException(message, error: e, stackTrace: st);
    } on FormatException catch (e, st) {
      developer.log('API Error (FormatException)', error: e, stackTrace: st);
      throw NetworkException(
        'Invalid response format from POST $path',
        error: e,
        stackTrace: st,
      );
    } on UnauthorizedException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e, st) {
      developer.log('API Error', error: e, stackTrace: st);
      throw NetworkException(
        'Network error occurred while making POST request to $path',
        error: e,
        stackTrace: st,
      );
    }
  }
}
