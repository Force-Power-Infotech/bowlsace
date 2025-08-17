import '../models/practice_session.dart';

class PracticeService {
  Future<void> savePracticeSession(PracticeSession session) async {
    // TODO: Implement API call to save practice session
    // For now, we'll just print the session details
    print('Saving practice session: ${session.toJson()}');
  }

  Future<List<PracticeSession>> getPracticeSessions(String userId) async {
    // TODO: Implement API call to get practice sessions
    return [];
  }

  Future<PracticeSession> getPracticeSession(String id) async {
    // TODO: Implement API call to get practice session details
    throw UnimplementedError();
  }
}
