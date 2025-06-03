import 'package:flutter/foundation.dart';
import '../models/challenge.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _challenges = [];
  List<Challenge> _pendingChallenges = [];
  Challenge? _selectedChallenge;
  bool _isLoading = false;

  List<Challenge> get challenges => _challenges;
  List<Challenge> get pendingChallenges => _pendingChallenges;
  Challenge? get selectedChallenge => _selectedChallenge;
  bool get isLoading => _isLoading;

  void setChallenges(List<Challenge> challenges) {
    _challenges = challenges;
    notifyListeners();
  }

  void setPendingChallenges(List<Challenge> challenges) {
    _pendingChallenges = challenges;
    notifyListeners();
  }

  void setSelectedChallenge(Challenge challenge) {
    _selectedChallenge = challenge;
    notifyListeners();
  }

  void clearSelectedChallenge() {
    _selectedChallenge = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void addChallenge(Challenge challenge) {
    _challenges.add(challenge);

    // Also add to pending challenges if it's pending
    if (challenge.status == 'PENDING') {
      _pendingChallenges.add(challenge);
    }

    notifyListeners();
  }

  void addSentChallenge(Challenge challenge) {
    addChallenge(challenge);
  }

  void updateChallenge(Challenge challenge) {
    // Update in main challenges list
    final index = _challenges.indexWhere((c) => c.id == challenge.id);
    if (index != -1) {
      _challenges[index] = challenge;
    } else {
      _challenges.add(challenge);
    }

    // Update in pending challenges list if applicable
    final pendingIndex = _pendingChallenges.indexWhere(
      (c) => c.id == challenge.id,
    );
    if (challenge.status == 'PENDING') {
      if (pendingIndex != -1) {
        _pendingChallenges[pendingIndex] = challenge;
      } else {
        _pendingChallenges.add(challenge);
      }
    } else if (pendingIndex != -1) {
      // Remove from pending if status changed
      _pendingChallenges.removeAt(pendingIndex);
    }

    // Update selected challenge if it's the same one
    if (_selectedChallenge != null && _selectedChallenge!.id == challenge.id) {
      _selectedChallenge = challenge;
    }

    notifyListeners();
  }

  void removeChallenge(int challengeId) {
    _challenges.removeWhere((c) => c.id == challengeId);
    _pendingChallenges.removeWhere((c) => c.id == challengeId);

    // Clear selected challenge if it's the same one
    if (_selectedChallenge != null && _selectedChallenge!.id == challengeId) {
      _selectedChallenge = null;
    }

    notifyListeners();
  }

  void clearChallenges() {
    _challenges = [];
    _pendingChallenges = [];
    _selectedChallenge = null;
    notifyListeners();
  }
}
