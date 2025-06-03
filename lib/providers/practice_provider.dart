import 'package:flutter/foundation.dart';
import '../models/practice_session.dart';

class PracticeProvider extends ChangeNotifier {
  List<Session> _sessions = [];
  Session? _currentSession;
  bool _isLoading = false;
  bool _needsRefresh = false;

  List<Session> get sessions => _sessions;
  Session? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  bool get needsRefresh => _needsRefresh;

  void setSessions(List<Session> sessions) {
    _sessions = sessions;
    _needsRefresh = false;
    notifyListeners();
  }

  void setCurrentSession(Session session) {
    _currentSession = session;
    notifyListeners();
  }

  void addSession(Session session) {
    _sessions.add(session);
    notifyListeners();
  }

  void updateSession(Session session) {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;

      // If this is the current session, update it too
      if (_currentSession != null && _currentSession!.id == session.id) {
        _currentSession = session;
      }

      notifyListeners();
    }
  }

  void removeSession(int sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);

    // If this is the current session, clear it
    if (_currentSession != null && _currentSession!.id == sessionId) {
      _currentSession = null;
    }

    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void triggerRefresh() {
    _needsRefresh = true;
    notifyListeners();
  }

  void clearSessions() {
    _sessions = [];
    _currentSession = null;
    notifyListeners();
  }
}
