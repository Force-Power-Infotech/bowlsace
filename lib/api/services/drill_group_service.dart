import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../../models/drill_group.dart';

class DrillGroupService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<DrillGroup>> getDrillGroups({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final url = Uri.parse(
          '$baseUrl${ApiConfig.drillGroups}?skip=$skip&limit=$limit');
      print('[API] 🌐 GET drill groups: $url');

      final response = await http.get(url);

      print('[API] 📥 Response status: ${response.statusCode}');
      print('[API] 📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) => DrillGroup.fromJson({
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
        })).toList();
      } else {
        print('[API] ❌ Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load drill groups: ${response.statusCode}');
      }
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
      final url = Uri.parse('$baseUrl${ApiConfig.drillGroups}');
      print('[API] 🌐 Creating drill group: $url');

      // Create the request body according to API specs
      final requestBody = {
        'name': name,
        'description': description ?? '',
        'drill_ids': drillIds ?? [],
        'is_public': isPublic,
        'tags': tags ?? [],
        'difficulty': difficulty,
      };

      print('[API] 📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('[API] 📥 Response status: ${response.statusCode}');
      print('[API] 📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DrillGroup.fromJson({
          'id': json['id'],
          'name': json['name'],
          'description': json['description'],
          'userId': json['user_id'],
          'isPublic': json['is_public'],
          'difficulty': json['difficulty'],
          'tags': json['tags'],
          'createdAt': json['created_at'],
          'updatedAt': json['updated_at'],
          'drill_ids': json['drill_ids'] ?? [],
          'drills': [], // New group starts with no drills
        });
      } else {
        print('[API] ❌ Error response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 422) {
          try {
            final errorBody = jsonDecode(response.body);
            final validationErrors = (errorBody['detail'] as List)
                .map((e) => '${e['msg']} (${e['loc'].join('.')})')
                .join(', ');
            throw Exception('Validation error: $validationErrors');
          } catch (e) {
            throw Exception('Invalid request data: ${response.body}');
          }
        }

        throw Exception('Failed to create drill group: ${response.statusCode}');
      }
    } catch (e) {
      print('[API] ❌ Error creating drill group: $e');
      rethrow;
    }
  }
}
