import '../../../api/api_client.dart';
import '../../../models/drill_group.dart';
import 'package:bowlsace/api/api_config.dart';

class DrillGroupApi {
  final ApiClient _apiClient;

  DrillGroupApi(this._apiClient);

  Future<List<DrillGroup>> getDrillGroups({
    String? search,
    int limit = 10,
  }) async {
    String endpoint = ApiConfig.drillGroups;
    List<String> queryParams = [];

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
    return (response as List).map((item) => DrillGroup.fromJson(item)).toList();
  }

  Future<DrillGroup> getDrillGroup(int groupId) async {
    final response = await _apiClient.get('${ApiConfig.drillGroups}/$groupId');
    return DrillGroup.fromJson(response);
  }

  // For admin functionality
  Future<DrillGroup> createDrillGroup(Map<String, dynamic> groupData) async {
    final response = await _apiClient.post(ApiConfig.drillGroups, groupData);
    return DrillGroup.fromJson(response);
  }

  Future<DrillGroup> updateDrillGroup(
    int groupId,
    Map<String, dynamic> groupData,
  ) async {
    final response = await _apiClient.put(
      '${ApiConfig.drillGroups}/$groupId',
      groupData,
    );
    return DrillGroup.fromJson(response);
  }

  Future<void> deleteDrillGroup(int groupId) async {
    await _apiClient.delete('${ApiConfig.drillGroups}/$groupId');
  }

  Future<DrillGroup> addDrillToGroup(int groupId, int drillId) async {
    final response = await _apiClient.post(
      '${ApiConfig.drillGroups}/$groupId/drills',
      {'drill_id': drillId},
    );
    return DrillGroup.fromJson(response);
  }

  Future<DrillGroup> removeDrillFromGroup(int groupId, int drillId) async {
    final response = await _apiClient.delete(
      '${ApiConfig.drillGroups}/$groupId/drills/$drillId',
    );
    return DrillGroup.fromJson(response);
  }
}
