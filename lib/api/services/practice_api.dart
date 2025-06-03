import '../api_client.dart';
import '../../models/practice_session.dart';
import '../../models/shot.dart';
import '../api_config.dart';

class PracticeApi {
  final ApiClient _apiClient;

  PracticeApi(this._apiClient);

  Future<List<Session>> getSessions({int limit = 10}) async {
    final response = await _apiClient.get(
      '${ApiConfig.practiceSession}?limit=$limit',
    );
    return (response as List).map((item) => Session.fromJson(item)).toList();
  }

  Future<Session> createSession(SessionCreate sessionData) async {
    final response = await _apiClient.post(
      ApiConfig.practiceSession,
      sessionData.toJson(),
    );
    return Session.fromJson(response);
  }

  Future<Session> updateSession(int sessionId, SessionUpdate data) async {
    final response = await _apiClient.put(
      '${ApiConfig.practiceSession}/$sessionId',
      data.toJson(),
    );
    return Session.fromJson(response);
  }

  Future<void> addShot(int sessionId, Shot shot) async {
    await _apiClient.post(
      '${ApiConfig.practiceSession}/$sessionId/shots',
      shot.toJson(),
    );
  }

  Future<void> deleteSession(int sessionId) async {
    await _apiClient.delete('${ApiConfig.practiceSession}/$sessionId');
  }

  Future<List<Session>> getRecentSessions({int limit = 5}) async {
    final response = await _apiClient.get(
      '${ApiConfig.practiceSession}?limit=$limit&sort=recent',
    );
    return (response as List).map((item) => Session.fromJson(item)).toList();
  }

  Future<void> deleteShot(int sessionId, int shotId) async {
    await _apiClient.delete(
      '${ApiConfig.practiceSession}/$sessionId/shots/$shotId',
    );
  }

  Future<void> updateShot(int sessionId, Shot shot) async {
    await _apiClient.put(
      '${ApiConfig.practiceSession}/$sessionId/shots/${shot.id}',
      shot.toJson(),
    );
  }
}
