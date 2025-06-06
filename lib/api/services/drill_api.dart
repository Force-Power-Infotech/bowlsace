import '../../../api/api_client.dart';
import '../../../models/drill.dart';
import 'package:bowlsace/api/api_config.dart';

class DrillApi {
  final ApiClient _apiClient;

  DrillApi(this._apiClient);

  Future<List<Drill>> getDrills({
    int? difficulty,
    String? search,
    int limit = 10,
  }) async {
    String endpoint = ApiConfig.drills;
    List<String> queryParams = [];

    if (difficulty != null) {
      queryParams.add('difficulty=$difficulty');
    }

    if (search != null && search.isNotEmpty) {
      queryParams.add('search=$search');
    }

    if (limit > 0) {
      queryParams.add('limit=$limit');
    }

    if (queryParams.isNotEmpty) {
      endpoint = '$endpoint?${queryParams.join('&')}';
    }

    final response = await _apiClient.get(endpoint);

    List<dynamic> drillsList;

    // Check if response has a data field
    if (response.containsKey('data') && response['data'] is List) {
      drillsList = response['data'] as List<dynamic>;
    }
    // Check if response is directly a list in items field
    else if (response.containsKey('items') && response['items'] is List) {
      drillsList = response['items'] as List<dynamic>;
    }
    // If neither, return empty list
    else {
      return [];
    }

    return drillsList
        .map((item) => Drill.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Drill> getDrill(int drillId) async {
    final response = await _apiClient.get('${ApiConfig.drills}/$drillId');

    if (response.containsKey('data')) {
      return Drill.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      return Drill.fromJson(response);
    }
  }

  // For admin functionality
  Future<Drill> createDrill(Map<String, dynamic> drillData) async {
    final response = await _apiClient.post(ApiConfig.drills, drillData);

    if (response.containsKey('data')) {
      return Drill.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      return Drill.fromJson(response);
    }
  }

  Future<Drill> updateDrill(int drillId, Map<String, dynamic> drillData) async {
    final response = await _apiClient.put(
      '${ApiConfig.drills}/$drillId',
      drillData,
    );

    if (response.containsKey('data')) {
      return Drill.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      return Drill.fromJson(response);
    }
  }

  Future<void> deleteDrill(int drillId) async {
    await _apiClient.delete('${ApiConfig.drills}/$drillId');
  }
}
