import 'package:flutter/foundation.dart';
import '../models/practice_session.dart';
import '../models/drill_group.dart';
import '../models/drill.dart';
import '../api/services/drill_group_service.dart';

class PracticeProvider extends ChangeNotifier {
  final _drillGroupService = DrillGroupService();

  List<Session> _sessions = [];
  List<DrillGroup> _drillGroups = [];
  Session? _currentSession;
  DrillGroup? _selectedDrillGroup;
  Drill? _selectedDrill;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Session> get sessions => _sessions;
  List<DrillGroup> get drillGroups => _drillGroups;
  Session? get currentSession => _currentSession;
  DrillGroup? get selectedDrillGroup => _selectedDrillGroup;
  Drill? get selectedDrill => _selectedDrill;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Drill Groups Methods
  void setDrillGroups(List<DrillGroup> groups) {
    _drillGroups = groups;
    notifyListeners();
  }

  void addDrillGroup(DrillGroup group) {
    _drillGroups.add(group);
    notifyListeners();
  }

  void updateDrillGroup(DrillGroup updatedGroup) {
    final index = _drillGroups.indexWhere((g) => g.id == updatedGroup.id);
    if (index != -1) {
      _drillGroups[index] = updatedGroup;
      if (_selectedDrillGroup?.id == updatedGroup.id) {
        _selectedDrillGroup = updatedGroup;
      }
      notifyListeners();
    }
  }

  void removeDrillGroup(int groupId) {
    _drillGroups.removeWhere((g) => g.id == groupId);
    if (_selectedDrillGroup?.id == groupId) {
      _selectedDrillGroup = null;
      _selectedDrill = null;
    }
    notifyListeners();
  }

  void setSelectedDrillGroup(DrillGroup? group) {
    _selectedDrillGroup = group;
    notifyListeners();
  }

  void setSelectedDrill(Drill? drill) {
    _selectedDrill = drill;
    notifyListeners();
  }

  // Session Methods
  // Set all sessions
  void setSessions(List<Session> sessions) {
    _sessions = sessions;
    notifyListeners();
  }

  // Set current session
  void setCurrentSession(Session? session) {
    _currentSession = session;
    notifyListeners();
  }

  // Add a single session
  void addSession(Session session) {
    _sessions.insert(0, session); // Add to the beginning of the list
    _currentSession = session; // Set as current session when adding new
    notifyListeners();
  }

  // Update a session
  void updateSession(Session updatedSession) {
    final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      // Update current session if it's the same one
      if (_currentSession?.id == updatedSession.id) {
        _currentSession = updatedSession;
      }
      notifyListeners();
    }
  }

  // Remove a session
  void removeSession(int sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    // Clear current session if it's the same one
    if (_currentSession?.id == sessionId) {
      _currentSession = null;
    }
    notifyListeners();
  }

  // Clear all sessions (e.g., on logout)
  void clearSessions() {
    _sessions = [];
    _currentSession = null;
    notifyListeners();
  }

  // Clear Methods
  void clearAll() {
    _sessions = [];
    _drillGroups = [];
    _currentSession = null;
    _selectedDrillGroup = null;
    _selectedDrill = null;
    _error = null;
    notifyListeners();
  }

  // Loading and Error State Methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // API Methods
  Future<void> getDrillGroups({int skip = 0, int limit = 100}) async {
    if (_isLoading) return; // Prevent multiple simultaneous calls

    setLoading(true);
    setError(null);

    try {
      print('🔄 Getting drill groups... skip: $skip, limit: $limit');
      final response = await _drillGroupService.getDrillGroups(
        skip: skip,
        limit: limit,
      );
      print('✅ Got ${response.length} drill groups');

      setDrillGroups(response);
    } catch (e) {
      print('❌ Error in getDrillGroups: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<DrillGroup?> createDrillGroup({
    required String name,
    String? description,
    List<int>? drillIds,
    bool isPublic = true,
    List<String>? tags,
    int difficulty = 1,
  }) async {
    if (_isLoading) return null;

    setLoading(true);
    setError(null);

    try {
      print('🔄 Creating drill group: $name');
      final newGroup = await _drillGroupService.createDrillGroup(
        name: name,
        description: description,
        drillIds: drillIds,
        isPublic: isPublic,
        tags: tags,
        difficulty: difficulty,
      );
      print('✅ Created drill group: ${newGroup.id}');

      // Add to local list
      addDrillGroup(newGroup);

      return newGroup;
    } catch (e) {
      print('❌ Error in createDrillGroup: $e');
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }
}
