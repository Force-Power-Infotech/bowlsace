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
    return (response as List).map((item) => Drill.fromJson(item)).toList();
  }

  Future<Drill> getDrill(int drillId) async {
    final response = await _apiClient.get('${ApiConfig.drills}/$drillId');
    return Drill.fromJson(response);
  }

  // For admin functionality
  Future<Drill> createDrill(Map<String, dynamic> drillData) async {
    final response = await _apiClient.post(ApiConfig.drills, drillData);
    return Drill.fromJson(response);
  }

  Future<Drill> updateDrill(int drillId, Map<String, dynamic> drillData) async {
    final response = await _apiClient.put(
      '${ApiConfig.drills}/$drillId',
      drillData,
    );
    return Drill.fromJson(response);
  }

  Future<void> deleteDrill(int drillId) async {
    await _apiClient.delete('${ApiConfig.drills}/$drillId');
  }
}
