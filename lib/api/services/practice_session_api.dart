import 'dart:developer' as developer;

import 'package:bowlsace/models/practice_session_detail.dart';

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
      "⚽ Recording shot - START",
      error: {
        "sessionId": sessionId,
        "drillEntryId": drillEntryId,
        "matLength": matLength,
        "shotNumber": shotNumber,
        "subDrillId": subDrillId,
        "useSubDrills": useSubDrills,
        "endpoint": "/practice-sessions/$sessionId/shots",
      },
    );

    final body = {
      "drillEntryId": drillEntryId,
      "matLength": matLength,
      "shotNumber": shotNumber,
      if (subDrillId != null) "subDrillId": subDrillId,
      "useSubDrills": useSubDrills,
    };

    developer.log("⚽ Shot request payload", error: body);

    try {
      final response = await _apiClient.post(
        "/practice-sessions/$sessionId/shots",
        body,
      );

      developer.log(
        "✅ Shot recorded successfully",
        error: {
          "shotId": response is Map<String, dynamic> ? response["id"] : null,
          "createdAt": response is Map<String, dynamic>
              ? response["created_at"]
              : null,
          "drillEntryId": response is Map<String, dynamic>
              ? response["drill_entry_id"]
              : null,
          "raw": response,
        },
      );

      if (response is! Map<String, dynamic>) {
        throw FormatException(
          "Unexpected response format: ${response.runtimeType}. Expected Map<String, dynamic>.",
        );
      }

      return response;
    } catch (e, stackTrace) {
      developer.log(
        "❌ Error recording shot",
        error: {"error": e.toString(), "payload": body, "sessionId": sessionId},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Fetch a single practice session by ID and parse full details.
  Future<PracticeSessionDetail> getPracticeSessionById({
    required String sessionId,
  }) async {
    developer.log(
      "Fetching practice session by ID",
      error: {
        "sessionId": sessionId,
        "endpoint": "/practice-sessions/$sessionId",
      },
    );

    try {
      final resp = await _apiClient.get('/practice-sessions/$sessionId');

      if (resp is! Map<String, dynamic>) {
        // throw ApiException(
        //   500,
        //   message:
        //       'Unexpected response type for getPracticeSessionById: ${resp.runtimeType}',
        //   body: resp,
        // );
      }

      final detail = PracticeSessionDetail.fromJson(resp);

      developer.log(
        "Fetched practice session",
        error: {
          "sessionId": detail.id,
          "drillCount": detail.drills.length,
          "totalShots": detail.totalShots,
          "avgAccuracy": detail.avgAccuracy,
        },
      );

      return detail;
    } catch (e, st) {
      developer.log(
        "Error fetching practice session",
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
