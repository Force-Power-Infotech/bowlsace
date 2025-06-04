import '../api/services/practice_api.dart';
import '../utils/local_storage.dart';
import '../models/practice_session.dart';
import '../models/drill_group.dart';
import '../models/drill.dart';
import '../models/shot.dart';

class PracticeRepository {
  final PracticeApi _practiceApi;
  final LocalStorage _localStorage;

  PracticeRepository(this._practiceApi, this._localStorage);

  // Drill Groups
  Future<List<DrillGroup>> getDrillGroups() async {
    try {
      final groups = await _practiceApi.getDrillGroups();
      return groups;
    } catch (e) {
      return [];
    }
  }

  Future<DrillGroup> createDrillGroup(DrillGroup drillGroup) async {
    try {
      final createdGroup = await _practiceApi.createDrillGroup(drillGroup);
      return createdGroup;
    } catch (e) {
      rethrow;
    }
  }

  Future<DrillGroup> updateDrillGroup(DrillGroup drillGroup) async {
    try {
      final updatedGroup = await _practiceApi.updateDrillGroup(drillGroup);
      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDrillGroup(int groupId) async {
    try {
      await _practiceApi.deleteDrillGroup(groupId);
    } catch (e) {
      rethrow;
    }
  }

  // Practice Sessions
  Future<List<Session>> getSessions({int? page, int? pageSize}) async {
    try {
      final sessions = await _practiceApi.getSessions();
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<List<Session>> getRecentSessions({int limit = 5}) async {
    try {
      final sessions = await _practiceApi.getRecentSessions(limit: limit);
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<Session> createSession(SessionCreate data) async {
    try {
      final session = await _practiceApi.createSession(data);
      return session;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSession(int sessionId, SessionUpdate update) async {
    try {
      await _practiceApi.updateSession(sessionId, update);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      await _practiceApi.deleteSession(sessionId);
    } catch (e) {
      rethrow;
    }
  }

  // Shot Management
  Future<void> addShot(int sessionId, Shot shot) async {
    try {
      await _practiceApi.addShot(sessionId, shot);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateShot(int sessionId, Shot shot) async {
    try {
      await _practiceApi.updateShot(sessionId, shot);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteShot(int sessionId, int shotId) async {
    try {
      await _practiceApi.deleteShot(sessionId, shotId);
    } catch (e) {
      rethrow;
    }
  }
}
