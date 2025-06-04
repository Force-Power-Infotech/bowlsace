import '../api/services/practice_api.dart';
import '../api/services/drill_group_api.dart';
import '../utils/local_storage.dart';
import '../models/practice_session.dart';
import '../models/drill_group.dart';
import '../models/drill.dart';
import '../models/shot.dart';

class PracticeRepository {
  final PracticeApi _practiceApi;
  final DrillGroupApi _drillGroupApi;
  final LocalStorage _localStorage;

  PracticeRepository(
    this._practiceApi,
    this._drillGroupApi,
    this._localStorage,
  );

  // Drill Groups
  Future<List<DrillGroup>> getDrillGroups({
    String? search,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final groups = await _drillGroupApi.getDrillGroups(
        search: search,
        skip: skip,
        limit: limit,
      );

      // Cache the drill groups if we're loading the first page
      if (skip == 0) {
        await _localStorage.setItem(
          'drill_groups',
          groups.map((g) => g.toJson()).toList(),
        );
      }

      return groups;
    } catch (e) {
      print('Error fetching drill groups: $e');
      // Try to get from local cache only for the first page
      if (skip == 0) {
        final cached = await _localStorage.getItem('drill_groups');
        if (cached != null) {
          try {
            final groups = (cached as List)
                .map((json) => DrillGroup.fromJson(json))
                .toList();

            // Apply filters if needed
            if (search != null && search.isNotEmpty) {
              final searchLower = search.toLowerCase();
              return groups
                  .where(
                    (g) =>
                        g.name.toLowerCase().contains(searchLower) ||
                        g.description.toLowerCase().contains(searchLower) ||
                        g.tags.any(
                          (tag) => tag.toLowerCase().contains(searchLower),
                        ),
                  )
                  .take(limit)
                  .toList();
            }

            return groups.take(limit).toList();
          } catch (e) {
            print('Error parsing cached drill groups: $e');
            return [];
          }
        }
      }
      return [];
    }
  }

  Future<DrillGroup> createDrillGroup(Map<String, dynamic> groupData) async {
    try {
      final createdGroup = await _drillGroupApi.createDrillGroup(groupData);
      return createdGroup;
    } catch (e) {
      print('Error creating drill group: $e');
      rethrow;
    }
  }

  Future<DrillGroup> updateDrillGroup(DrillGroup drillGroup) async {
    try {
      final updatedGroup = await _drillGroupApi.updateDrillGroup(
        drillGroup.id,
        drillGroup.toJson(),
      );
      return updatedGroup;
    } catch (e) {
      print('Error updating drill group: $e');
      rethrow;
    }
  }

  Future<void> deleteDrillGroup(int groupId) async {
    try {
      await _drillGroupApi.deleteDrillGroup(groupId);
    } catch (e) {
      print('Error deleting drill group: $e');
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
