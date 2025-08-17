import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:developer' as developer;
import '../models/meta_drill_group.dart';
import '../models/drill_group.dart' as dg;
import '../models/meta_drill_group_detail.dart';
import '../models/drill_group_detail.dart';

class DrillService {
  static const String baseUrl = 'https://ledboard.forcempower.com:8443/api/v1';
  late final Dio _dio;

  DrillService() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl, validateStatus: (status) => true));

    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  void _logApiCall(String endpoint, Response response) {
    developer.log(
      'API Call to: $endpoint\n'
      'Status Code: ${response.statusCode}\n'
      'Response: ${response.data}',
      name: 'DrillService',
    );
  }

  void _logApiError(String endpoint, dynamic error, StackTrace? stackTrace) {
    developer.log(
      'API Error for: $endpoint\n'
      'Error: $error\n'
      'StackTrace: $stackTrace',
      name: 'DrillService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<List<MetaDrillGroup>> getMetaDrillGroups({
    int skip = 0,
    int limit = 100,
  }) async {
    const endpoint = '/meta-drill-groups/meta-drill-groups/';
    try {
      developer.log(
        'Fetching meta drill groups from: $baseUrl$endpoint',
        name: 'DrillService',
      );

      final response = await _dio.get(endpoint);
      _logApiCall(endpoint, response);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        final groups = jsonList
            .map((json) => MetaDrillGroup.fromJson(json))
            .toList();
        developer.log(
          'Successfully fetched ${groups.length} meta drill groups',
          name: 'DrillService',
        );
        return groups;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Failed to load meta drill groups. Status: ${response.statusCode}, Body: ${response.data}',
        );
      }
    } catch (e, stackTrace) {
      _logApiError(endpoint, e, stackTrace);
      rethrow;
    }
  }

  Future<List<dg.DrillGroup>> getDrillGroups({
    int skip = 0,
    int limit = 100,
  }) async {
    final endpoint = '/drill-groups/?skip=$skip&limit=$limit';
    try {
      developer.log(
        'Fetching drill groups from: $baseUrl$endpoint',
        name: 'DrillService',
      );

      final response = await _dio.get(endpoint);
      _logApiCall(endpoint, response);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        final groups = jsonList
            .map((json) => dg.DrillGroup.fromJson(json))
            .toList();
        developer.log(
          'Successfully fetched ${groups.length} drill groups',
          name: 'DrillService',
        );
        return groups;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Failed to load drill groups. Status: ${response.statusCode}, Body: ${response.data}',
        );
      }
    } catch (e, stackTrace) {
      _logApiError(endpoint, e, stackTrace);
      rethrow;
    }
  }

  Future<MetaDrillGroupDetail> getMetaDrillGroupDetail(String id) async {
    final endpoint = '/meta-drill-groups/meta-drill-groups/$id';
    try {
      developer.log(
        'Fetching meta drill group detail from: $baseUrl$endpoint',
        name: 'DrillService',
      );

      final response = await _dio.get(endpoint);
      _logApiCall(endpoint, response);

      if (response.statusCode == 200) {
        final detail = MetaDrillGroupDetail.fromJson(response.data);
        developer.log(
          'Successfully fetched meta drill group detail for id: $id',
          name: 'DrillService',
        );
        return detail;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Failed to load meta drill group detail. Status: ${response.statusCode}, Body: ${response.data}',
        );
      }
    } catch (e, stackTrace) {
      _logApiError(endpoint, e, stackTrace);
      rethrow;
    }
  }

  Future<DrillGroupDetail> getDrillGroupDetail(String id) async {
    final endpoint = '/drill-groups/$id';
    try {
      developer.log(
        'Fetching drill group detail from: $baseUrl$endpoint',
        name: 'DrillService',
      );

      final response = await _dio.get(endpoint);
      _logApiCall(endpoint, response);

      if (response.statusCode == 200) {
        final detail = DrillGroupDetail.fromJson(response.data);
        developer.log(
          'Successfully fetched drill group detail for id: $id',
          name: 'DrillService',
        );
        return detail;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Failed to load drill group detail. Status: ${response.statusCode}, Body: ${response.data}',
        );
      }
    } catch (e, stackTrace) {
      _logApiError(endpoint, e, stackTrace);
      rethrow;
    }
  }
}
