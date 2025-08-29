import 'dart:developer' as developer;
import '../api_client.dart';

class PracticeSessionApi {
  final ApiClient _apiClient;

  PracticeSessionApi(this._apiClient);

  /// Creates a new practice session with drills and sub-drills
  Future<Map<String, dynamic>> createPracticeSession({
    required String userId,
    required String drillGroupId,
    required String drillGroupName,
    required int totalDuration,
    required DateTime timestamp,
    required List<Map<String, dynamic>> drills,
    String? idempotencyKey,
  }) async {
    final body = {
      "userId": userId,
      "drillGroupId": drillGroupId,
      "drillGroupName": drillGroupName,
      "totalDuration": totalDuration,
      "timestamp": timestamp.toIso8601String(),
      "drills": drills
          .map(
            (drill) => {
              "id": drill["id"],
              "name": drill["name"],
              "duration": drill["duration"],
              "shots": drill["shots"] ?? 0,
              "accuracy": drill["accuracy"] ?? 100,
              "notes": drill["notes"] ?? "",
              // Sub-drills must include a required 'title' per API validation
              "subDrills":
                  (drill["subDrills"] as List?)
                      ?.map(
                        (subDrill) => {
                          "id": subDrill["id"],
                          "title": subDrill["title"] ?? subDrill["name"],
                          "duration": subDrill["duration"] ?? drill["duration"],
                          "shots": subDrill["shots"] ?? 0,
                        },
                      )
                      .toList() ??
                  [],
            },
          )
          .toList(),
    };

    developer.log("Creating practice session - Request Body", error: body);

    try {
      final response = await _apiClient.post(
        "/practice-sessions/",
        body,
        extraHeaders: {
          if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
        },
      );

      developer.log("Practice session API Response", error: response);

      if (response is! Map<String, dynamic>) {
        throw FormatException(
          "Unexpected response format: ${response.runtimeType}. Expected Map<String, dynamic>.",
        );
      }

      developer.log(
        "Practice session created",
        error: {
          "sessionId": response["id"],
          "totalShots": response["total_shots"],
          "avgAccuracy": response["avg_accuracy"],
          "startedAt": response["started_at"],
        },
      );

      return response;
    } catch (e, stackTrace) {
      developer.log(
        "Error creating practice session",
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Records a single shot for a practice session
  Future<Map<String, dynamic>> recordShot({
    required String sessionId,
    required String drillEntryId,
    required int matLength,
    required int shotNumber,
    String? subDrillId,
    bool useSubDrills = false,
  }) async {
    developer.log(
      "Recording shot",
      error: {
        "sessionId": sessionId,
        "drillEntryId": drillEntryId,
        "matLength": matLength,
        "shotNumber": shotNumber,
        "subDrillId": subDrillId,
        "useSubDrills": useSubDrills,
      },
    );

    final body = {
      "drill_entry_id": drillEntryId,
      "mat_length": matLength,
      "shot_number": shotNumber,
      "sub_drill_id": subDrillId,
      "use_sub_drills": useSubDrills,
    };

    final response = await _apiClient.post(
      "/practice-sessions/$sessionId/shots/",
      body,
    );

    developer.log(
      "Shot recorded",
      error: {
        "shotId": response["id"],
        "createdAt": response["created_at"],
        "drillEntryId": response["drill_entry_id"],
      },
    );

    return response;
  }
}
