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

      print(
        'API response type for createPracticeSessions: ${response.runtimeType}',
      );

      // Handle direct list response
      if (response is List) {
        print(
          'Received list response with ${response.length} practice sessions',
        );
        final List<PracticeSession> sessions = [];
        for (var i = 0; i < response.length; i++) {
          final item = response[i];
          if (item is Map<String, dynamic>) {
            try {
              sessions.add(PracticeSession.fromJson(item));
            } catch (e) {
              print('Error parsing practice session item: $e');
            }
          }
        }
        return sessions;
      }

      // Handle Map responses
      if (response is Map) {
        final responseMap = response;
        // Handle practice_sessions key in response
        if (responseMap.containsKey('practice_sessions')) {
          final practiceSessionsList = responseMap['practice_sessions'];
          if (practiceSessionsList is List) {
            final List<PracticeSession> sessions = [];
            for (var i = 0; i < practiceSessionsList.length; i++) {
              final json = practiceSessionsList[i];
              if (json is Map<String, dynamic>) {
                try {
                  sessions.add(PracticeSession.fromJson(json));
                } catch (e) {
                  print('Error parsing practice session item: $e');
                }
              }
            }
            return sessions;
          }
        }
        // Handle message-only response
        else if (responseMap.containsKey('message')) {
          // API returned just a message, likely success with empty list
          print('Received message response: ${responseMap['message']}');
          return [];
        }

        // Try to parse as a single item
        try {
          return [
            PracticeSession.fromJson(responseMap as Map<String, dynamic>),
          ];
        } catch (e) {
          print('Error parsing single response: $e');
        }
      }

      // Default fallback
      print(
        'Unhandled response format in createPracticeSessions: ${response.runtimeType}',
      );
      return [];
    } catch (e) {
      print('Error creating practice sessions: $e');
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

      print('API response type: ${response.runtimeType}');
      print(
        'API response sample: ${response is List ? (response.isNotEmpty ? response[0] : "empty list") : response}',
      );

      // Handle direct list response format (new API format)
      if (response is List) {
        print(
          'Received list response with ${response.length} practice sessions',
        );
        final List<PracticeSession> sessions = [];
        for (var i = 0; i < response.length; i++) {
          final item = response[i];
          if (item is Map<String, dynamic>) {
            try {
              sessions.add(PracticeSession.fromJson(item));
              print(
                'Successfully parsed practice session ${i + 1}/${response.length}',
              );
            } catch (e) {
              print('Error parsing practice session item ${i + 1}: $e');
              print('Problem item: $item');
            }
          } else {
            print('Item at index $i is not a Map: ${item.runtimeType}');
          }
        }

        if (sessions.isEmpty && response.isNotEmpty) {
          print('Warning: Could not parse any practice sessions from response');
        }

        return sessions;
      }

      // Handle Map response
      if (response is Map) {
        final responseMap = response;
        // Check for data field (older API format)
        if (responseMap.containsKey('data')) {
          final data = responseMap['data'];
          if (data is List) {
            print('Received data field with ${data.length} practice sessions');
            final List<PracticeSession> sessions = [];
            for (var i = 0; i < data.length; i++) {
              final item = data[i];
              if (item is Map<String, dynamic>) {
                try {
                  sessions.add(PracticeSession.fromJson(item));
                } catch (e) {
                  print(
                    'Error parsing practice session item from data field: $e',
                  );
                }
              }
            }
            return sessions;
          }
        }

        // Try to parse as a single item
        try {
          return [
            PracticeSession.fromJson(responseMap as Map<String, dynamic>),
          ];
        } catch (e) {
          print('Error parsing single response: $e');
        }
      }

      print('Unhandled response format: ${response.runtimeType}');
      return [];
    } catch (e) {
      print('Error getting practice sessions: $e');
      // Don't throw an exception, just return empty list and log the error
      print('Returning empty list instead of throwing exception');
      return [];
    }
  }
}
