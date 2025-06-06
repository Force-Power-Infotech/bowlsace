import '../api_client.dart';
import '../../models/practice_model.dart';

class PracticeSessionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PracticeSession>> createPracticeSessions({
    required int drillGroupId,
    required List<int> drillIds,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.post('/practice-sessions/', {
        'drill_group_id': drillGroupId,
        'drill_ids': drillIds,
        'user_id': userId,
      });

      if (response.containsKey('practice_sessions')) {
        final List<dynamic> practiceSessionsList =
            response['practice_sessions'] as List<dynamic>;
        return practiceSessionsList
            .map(
              (json) => PracticeSession.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (response.containsKey('message')) {
        // API returned just a message, likely success with empty list
        return [];
      } else {
        // Fallback handling
        try {
          if (response is List) {
            final List<dynamic> responseList = response as List<dynamic>;
            return responseList
                .map(
                  (json) =>
                      PracticeSession.fromJson(json as Map<String, dynamic>),
                )
                .toList();
          }
          // Single item response
          return [PracticeSession.fromJson(response)];
        } catch (parseError) {
          print('Error parsing practice session response: $parseError');
          return [];
        }
      }
    } catch (e) {
      throw Exception('Failed to create practice sessions: $e');
    }
  }

  Future<List<PracticeSession>> getUserPracticeSessions({
    required int userId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final response = await _apiClient.get(
        '/practice-sessions/user/$userId',
        queryParameters: queryParams,
      );

      // Direct list response (new API format)
      if (response is List) {
        return (response as List)
            .map((item) => PracticeSession.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      // Check if response is a Map with a 'data' field that is a List
      if (response is Map && response.containsKey('data')) {
        final data = response['data'] as List<dynamic>;
        return data
            .map((json) => PracticeSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Single item response
      try {
        return [PracticeSession.fromJson(response as Map<String, dynamic>)];
      } catch (e) {
        print('Error parsing practice session response: $e');
        return [];
      }
    } catch (e) {
      print('Error getting practice sessions: $e');
      throw Exception('Failed to get practice sessions: $e');
    }
  }
}
