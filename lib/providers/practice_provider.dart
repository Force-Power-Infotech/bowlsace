import 'package:flutter/material.dart';
import '../models/practice_session.dart';
import '../services/practice_service.dart';

class PracticeProvider extends ChangeNotifier {
  final PracticeService _practiceService = PracticeService();
  List<PracticeSession> _sessions = [];
  bool _isLoading = false;
  String? _error;

  List<PracticeSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPracticeSessions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _practiceService.getPracticeSessions(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> savePracticeSession(PracticeSession session) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _practiceService.savePracticeSession(session);
      _sessions = [session, ..._sessions];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
