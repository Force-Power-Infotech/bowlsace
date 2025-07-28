import 'dart:convert';
import '../api_client.dart';
import '../api_config.dart';
import '../../models/drill_group.dart';

class DrillGroupService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DrillGroup>> getDrillGroups({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      print('🔄 Getting drill groups... skip: $skip, limit: $limit');

      final response = await _apiClient.get(
        ApiConfig.drillGroups,
        queryParameters: {'skip': skip.toString(), 'limit': limit.toString()},
      );

      final List<dynamic> jsonResponse = response as List<dynamic>;
      return jsonResponse
          .map(
            (json) => DrillGroup.fromJson({
              'id': json['id'],
              'name': json['name'],
              'description': json['description'],
              'userId': json['user_id'],
              'isPublic': json['is_public'],
              'difficulty': json['difficulty'],
              'tags': json['tags'],
              'createdAt': json['created_at'],
              'updatedAt': json['updated_at'],
              'drills': json['drills'] ?? [],
              'drill_ids': json['drill_ids'] ?? [],
            }),
          )
          .toList();
    } catch (e) {
      print('[API] ❌ Error fetching drill groups: $e');
      rethrow;
    }
  }

  Future<DrillGroup> createDrillGroup({
    required String name,
    String? description,
    List<int>? drillIds,
    bool isPublic = true,
    List<String>? tags,
    int difficulty = 1,
  }) async {
    try {
      print('[API] 🌐 Creating drill group');

      final requestBody = {
        'name': name,
        'description': description ?? '',
        'drill_ids': drillIds ?? [],
        'is_public': isPublic,
        'tags': tags ?? [],
        'difficulty': difficulty,
      };

      print('[API] 📤 Request body: ${jsonEncode(requestBody)}');

      final response = await _apiClient.post(
        ApiConfig.drillGroups,
        requestBody,
      );

      return DrillGroup.fromJson({
        'id': response['id'],
        'name': response['name'],
        'description': response['description'],
        'userId': response['user_id'],
        'isPublic': response['is_public'],
        'difficulty': response['difficulty'],
        'tags': response['tags'],
        'createdAt': response['created_at'],
        'updatedAt': response['updated_at'],
        'drill_ids': response['drill_ids'] ?? [],
        'drills': [], // New group starts with no drills
      });
    } catch (e) {
      print('[API] ❌ Error creating drill group: $e');
      rethrow;
    }
  }
}
