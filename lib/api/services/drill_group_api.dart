import '../../../api/api_client.dart';
import '../../../models/drill_group.dart';
import 'package:bowlsace/api/api_config.dart';

class DrillGroupApi {
  final ApiClient _apiClient;

  DrillGroupApi(this._apiClient);

  Future<List<DrillGroup>> getDrillGroups({
    String? search,
    int skip = 0,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiClient.get(
      ApiConfig.drillGroups,
      queryParameters: queryParams,
    );

    print('DrillGroups API Response: $response');

    List<dynamic> drillGroupsList;

    // Check if response has a data field
    if (response.containsKey('data') && response['data'] is List) {
      drillGroupsList = response['data'] as List<dynamic>;
    }
    // Check if response is directly a list in items field
    else if (response.containsKey('items') && response['items'] is List) {
      drillGroupsList = response['items'] as List<dynamic>;
    }
    // If neither, throw an exception
    else {
      print(
        'DrillGroups API Error: Expected List but got ${response.runtimeType}',
      );
      throw FormatException(
        'Expected List response but got ${response.runtimeType}',
      );
    }

    try {
      final groups = drillGroupsList.map((json) {
        print('Processing drill group: $json');
        return DrillGroup.fromJson(json as Map<String, dynamic>);
      }).toList();
      print('Successfully parsed ${groups.length} drill groups');
      return groups;
    } catch (e, stackTrace) {
      print('Error parsing drill groups: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<DrillGroup> getDrillGroup(int groupId) async {
    final response = await _apiClient.get('${ApiConfig.drillGroups}/$groupId');

    if (response.containsKey('data')) {
      return DrillGroup.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      return DrillGroup.fromJson(response);
    }
  }

  // For admin functionality
  Future<DrillGroup> createDrillGroup(Map<String, dynamic> groupData) async {
    print('Creating drill group with data: $groupData');
    final response = await _apiClient.post(ApiConfig.drillGroups, groupData);
    print('Create drill group response: $response');

    try {
      if (response.containsKey('data')) {
        return DrillGroup.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        return DrillGroup.fromJson(response);
      }
    } catch (e, stackTrace) {
      print('Error parsing created drill group: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<DrillGroup> updateDrillGroup(
    int groupId,
    Map<String, dynamic> groupData,
  ) async {
    final response = await _apiClient.put(
      '${ApiConfig.drillGroups}/$groupId',
      groupData,
    );

    if (response.containsKey('data')) {
      return DrillGroup.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      return DrillGroup.fromJson(response);
    }
  }

  Future<void> deleteDrillGroup(int groupId) async {
    await _apiClient.delete('${ApiConfig.drillGroups}/$groupId');
  }

  Future<DrillGroup> addDrillToGroup(int groupId, int drillId) async {
    final response = await _apiClient.post(
      '${ApiConfig.drillGroups}/$groupId/drills',
      {'drill_id': drillId},
    );

    if (response.containsKey('data')) {
      return DrillGroup.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      return DrillGroup.fromJson(response);
    }
  }

  Future<DrillGroup> removeDrillFromGroup(int groupId, int drillId) async {
    final response = await _apiClient.delete(
      '${ApiConfig.drillGroups}/$groupId/drills/$drillId',
    );

    if (response.containsKey('data')) {
      return DrillGroup.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      return DrillGroup.fromJson(response);
    }
  }
}
