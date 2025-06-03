import '../api/services/practice_api.dart';
import '../models/practice_session.dart';
import '../models/shot.dart';
import '../utils/local_storage.dart';

class PracticeRepository {
  final PracticeApi _api;
  final LocalStorage _localStorage;

  PracticeRepository(this._api, this._localStorage);

  // Get sessions with offline support
  Future<List<Session>> getSessions() async {
    try {
      // Try to fetch from API
      final sessions = await _api.getSessions();

      // Cache the result locally
      await _cacheSessions(sessions);

      return sessions;
    } catch (e) {
      // On network error, return cached data
      final cachedSessions = await _getCachedSessions();
      return cachedSessions;
    }
  }

  // Get recent sessions
  Future<List<Session>> getRecentSessions({int limit = 5}) async {
    try {
      return await _api.getRecentSessions(limit: limit);
    } catch (e) {
      // On failure, return cached recent sessions if available
      final allSessions = await _getCachedSessions();
      allSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allSessions.take(limit).toList();
    }
  }

  // Create session with offline support
  Future<Session> createSession(SessionCreate data) async {
    try {
      // Try to create on the server
      final session = await _api.createSession(data);

      // Cache the session
      await _cacheSession(session);

      return session;
    } catch (e) {
      // Create a pending session locally
      final pendingSession = _createPendingSession(data);
      await _savePendingOperation('CREATE_SESSION', data);
      return pendingSession;
    }
  }

  // Update session
  Future<Session> updateSession(int sessionId, SessionUpdate data) async {
    try {
      final session = await _api.updateSession(sessionId, data);
      await _cacheSession(session);
      return session;
    } catch (e) {
      // Update in the cache and queue for syncing
      final existingSession = await _getCachedSession(sessionId);
      if (existingSession != null) {
        final updatedSession = _applyUpdate(existingSession, data);
        await _cacheSession(updatedSession);
        await _savePendingOperation('UPDATE_SESSION', data, id: sessionId);
        return updatedSession;
      }
      rethrow;
    }
  }

  // Add shot to a session
  Future<void> addShot(int sessionId, Shot shot) async {
    try {
      await _api.addShot(sessionId, shot);

      // Update the cached session
      final existingSession = await _getCachedSession(sessionId);
      if (existingSession != null) {
        final shots = existingSession.shots ?? <Shot>[];
        shots.add(shot);
        final updatedSession = Session(
          id: existingSession.id,
          name: existingSession.name,
          location: existingSession.location,
          notes: existingSession.notes,
          durationMinutes: existingSession.durationMinutes,
          userId: existingSession.userId,
          createdAt: existingSession.createdAt,
          shots: shots,
          isCompleted: existingSession.isCompleted,
        );
        await _cacheSession(updatedSession);
      }
    } catch (e) {
      // Queue the shot addition for later
      await _savePendingOperation('ADD_SHOT', shot.toJson(), id: sessionId);

      // Also update the local cache
      final existingSession = await _getCachedSession(sessionId);
      if (existingSession != null) {
        final shots = existingSession.shots ?? <Shot>[];
        shots.add(shot);
        final updatedSession = Session(
          id: existingSession.id,
          name: existingSession.name,
          location: existingSession.location,
          notes: existingSession.notes,
          durationMinutes: existingSession.durationMinutes,
          userId: existingSession.userId,
          createdAt: existingSession.createdAt,
          shots: shots,
          isCompleted: existingSession.isCompleted,
        );
        await _cacheSession(updatedSession);
      }
    }
  }

  // Delete shot from a session
  Future<void> deleteShot(int sessionId, int shotId) async {
    try {
      await _api.deleteShot(sessionId, shotId);

      // Update the cached session
      final existingSession = await _getCachedSession(sessionId);
      if (existingSession != null && existingSession.shots != null) {
        final updatedShots = existingSession.shots!
            .where((s) => s.id != shotId)
            .toList();
        final updatedSession = Session(
          id: existingSession.id,
          name: existingSession.name,
          location: existingSession.location,
          notes: existingSession.notes,
          durationMinutes: existingSession.durationMinutes,
          userId: existingSession.userId,
          createdAt: existingSession.createdAt,
          shots: updatedShots,
          isCompleted: existingSession.isCompleted,
        );
        await _cacheSession(updatedSession);
      }
    } catch (e) {
      // Queue the deletion for later
      await _savePendingOperation('DELETE_SHOT', {
        'shot_id': shotId,
      }, id: sessionId);

      // Also update the local cache
      final existingSession = await _getCachedSession(sessionId);
      if (existingSession != null && existingSession.shots != null) {
        final updatedShots = existingSession.shots!
            .where((s) => s.id != shotId)
            .toList();
        final updatedSession = Session(
          id: existingSession.id,
          name: existingSession.name,
          location: existingSession.location,
          notes: existingSession.notes,
          durationMinutes: existingSession.durationMinutes,
          userId: existingSession.userId,
          createdAt: existingSession.createdAt,
          shots: updatedShots,
          isCompleted: existingSession.isCompleted,
        );
        await _cacheSession(updatedSession);
      }
    }
  }

  // Update shot in a session
  Future<void> updateShot(int sessionId, Shot updatedShot) async {
    try {
      await _api.updateShot(sessionId, updatedShot);

      // Update the cached session
      final existingSession = await _getCachedSession(sessionId);
      if (existingSession != null && existingSession.shots != null) {
        final updatedShots = existingSession.shots!
            .map((s) => s.id == updatedShot.id ? updatedShot : s)
            .toList();

        final updatedSession = Session(
          id: existingSession.id,
          name: existingSession.name,
          location: existingSession.location,
          notes: existingSession.notes,
          durationMinutes: existingSession.durationMinutes,
          userId: existingSession.userId,
          createdAt: existingSession.createdAt,
          shots: updatedShots,
        );
        await _cacheSession(updatedSession);
      }
    } catch (e) {
      // Queue the update for later
      await _savePendingOperation(
        'UPDATE_SHOT',
        updatedShot.toJson(),
        id: sessionId,
      );

      // Also update the local cache
      final existingSession = await _getCachedSession(sessionId);
      if (existingSession != null && existingSession.shots != null) {
        final updatedShots = existingSession.shots!
            .map((s) => s.id == updatedShot.id ? updatedShot : s)
            .toList();

        final updatedSession = Session(
          id: existingSession.id,
          name: existingSession.name,
          location: existingSession.location,
          notes: existingSession.notes,
          durationMinutes: existingSession.durationMinutes,
          userId: existingSession.userId,
          createdAt: existingSession.createdAt,
          shots: updatedShots,
        );
        await _cacheSession(updatedSession);
      }
    }
  }

  // Sync pending operations
  Future<void> syncPendingOperations() async {
    final pendingOps = await _getPendingOperations();

    for (final op in pendingOps) {
      try {
        switch (op['type']) {
          case 'CREATE_SESSION':
            final data = SessionCreate(
              name: op['data']['name'],
              durationMinutes: op['data']['duration_minutes'],
              location: op['data']['location'],
              notes: op['data']['notes'],
            );
            await _api.createSession(data);
            break;
          case 'UPDATE_SESSION':
            if (op['id'] != null) {
              final data = SessionUpdate(
                name: op['data']['name'],
                durationMinutes: op['data']['duration_minutes'],
                location: op['data']['location'],
                notes: op['data']['notes'],
                isCompleted: op['data']['is_completed'],
              );
              await _api.updateSession(op['id'], data);
            }
            break;
          case 'ADD_SHOT':
            if (op['id'] != null) {
              // Recreate shot from the stored data
              // This is simplified and would need proper implementation
              final shotData = op['data'];
              final shot = Shot(
                id: shotData['id'] ?? 0, // May need a temporary ID
                sessionId: op['id'],
                drillType: shotData['drill_type'],
                result: ShotResult.values.byName(
                  shotData['result'].toLowerCase(),
                ),
                notes: shotData['notes'],
                timestamp: DateTime.parse(shotData['timestamp']),
              );
              await _api.addShot(op['id'], shot);
            }
            break;
        }

        // Remove from pending queue on success
        await _removePendingOperation(op['local_id']);
      } catch (e) {
        // Skip this operation but continue with others
        print('Failed to sync operation ${op['local_id']}: $e');
      }
    }
  }

  // Helper methods for caching
  Future<void> _cacheSessions(List<Session> sessions) async {
    await _localStorage.setItem(
      'sessions',
      sessions.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _cacheSession(Session session) async {
    final sessions = await _getCachedSessions();
    final index = sessions.indexWhere((e) => e.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    await _cacheSessions(sessions);
  }

  Future<List<Session>> _getCachedSessions() async {
    final data = await _localStorage.getItem('sessions');
    if (data == null) return [];
    return (data as List).map((e) => Session.fromJson(e)).toList();
  }

  Future<Session?> _getCachedSession(int id) async {
    final sessions = await _getCachedSessions();
    try {
      return sessions.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper method to create a pending session with a temporary ID
  Session _createPendingSession(SessionCreate data) {
    final now = DateTime.now();
    // Create a temporary negative ID for local-only sessions
    final tempId = -DateTime.now().millisecondsSinceEpoch;

    return Session(
      id: tempId,
      name: data.name,
      location: data.location,
      notes: data.notes,
      durationMinutes: data.durationMinutes,
      userId: 0, // Will be filled in on the server
      createdAt: now,
      shots: [],
      isCompleted: false,
    );
  }

  // Helper method to apply updates to a session
  Session _applyUpdate(Session session, SessionUpdate update) {
    return Session(
      id: session.id,
      name: update.name ?? session.name,
      location: update.location ?? session.location,
      notes: update.notes ?? session.notes,
      durationMinutes: update.durationMinutes ?? session.durationMinutes,
      userId: session.userId,
      createdAt: session.createdAt,
      shots: session.shots,
      isCompleted: update.isCompleted ?? session.isCompleted,
    );
  }

  // Methods for managing pending operations
  Future<void> _savePendingOperation(
    String type,
    dynamic data, {
    int? id,
  }) async {
    final pendingOps = await _getPendingOperations();
    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    pendingOps.add({
      'local_id': localId,
      'type': type,
      'id': id,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _localStorage.setItem('pending_operations', pendingOps);
  }

  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    final data = await _localStorage.getItem('pending_operations');
    if (data == null) return [];
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> _removePendingOperation(String localId) async {
    final pendingOps = await _getPendingOperations();
    final filtered = pendingOps
        .where((op) => op['local_id'] != localId)
        .toList();
    await _localStorage.setItem('pending_operations', filtered);
  }
}
