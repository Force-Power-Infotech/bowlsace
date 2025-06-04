import '../api_client.dart';
import '../../models/practice_session.dart';
import '../../models/drill_group.dart';
import '../../models/shot.dart';

class PracticeApi {
  final ApiClient _client;

  PracticeApi(this._client);

  // Note: Drill Groups functionality moved to DrillGroupApi

  // Practice Sessions
  Future<List<Session>> getSessions() async {
    final response = await _client.get('/practice/sessions');
    return (response.data as List)
        .map((json) => Session.fromJson(json))
        .toList();
  }

  Future<List<Session>> getRecentSessions({int limit = 5}) async {
    final response = await _client.get(
      '/practice/sessions',
      queryParameters: {'limit': limit.toString(), 'sort': '-created_at'},
    );
    return (response.data as List)
        .map((json) => Session.fromJson(json))
        .toList();
  }

  Future<Session> createSession(SessionCreate data) async {
    final response = await _client.post('/practice/sessions', data.toJson());
    return Session.fromJson(response.data);
  }

  Future<void> updateSession(int sessionId, SessionUpdate update) async {
    await _client.put('/practice/sessions/$sessionId', update.toJson());
  }

  Future<void> deleteSession(int sessionId) async {
    await _client.delete('/practice/sessions/$sessionId');
  }

  // Shot Management
  Future<void> addShot(int sessionId, Shot shot) async {
    await _client.post('/practice/sessions/$sessionId/shots', shot.toJson());
  }

  Future<void> updateShot(int sessionId, Shot shot) async {
    await _client.put(
      '/practice/sessions/$sessionId/shots/${shot.id}',
      shot.toJson(),
    );
  }

  Future<void> deleteShot(int sessionId, int shotId) async {
    await _client.delete('/practice/sessions/$sessionId/shots/$shotId');
  }
}
