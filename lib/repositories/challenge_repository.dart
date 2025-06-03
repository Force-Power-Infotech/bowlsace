import '../api/services/challenge_api.dart';
import '../models/challenge.dart';
import '../utils/local_storage.dart';

class ChallengeRepository {
  final ChallengeApi _api;
  final LocalStorage _localStorage;

  ChallengeRepository(this._api, this._localStorage);

  Future<List<Challenge>> getChallenges({String? status}) async {
    try {
      final challenges = await _api.getChallenges(status: status);

      // Cache challenges
      await _cacheChallenges(challenges);

      return challenges;
    } catch (e) {
      // On failure, try local cache
      return _getCachedChallenges(status: status);
    }
  }

  Future<List<Challenge>> getPendingChallenges() async {
    try {
      final challenges = await _api.getPendingChallenges();

      // Update cache with these pending challenges
      await _cachePendingChallenges(challenges);

      return challenges;
    } catch (e) {
      // On failure, try local cache
      return _getCachedChallenges(status: 'PENDING');
    }
  }

  Future<Challenge> getChallenge(int challengeId) async {
    try {
      final challenge = await _api.getChallenge(challengeId);

      // Cache this individual challenge
      await _cacheChallenge(challenge);

      return challenge;
    } catch (e) {
      // Try to get from local cache
      final cachedChallenge = await _getCachedChallenge(challengeId);
      if (cachedChallenge != null) {
        return cachedChallenge;
      }

      // If not found in cache, rethrow
      rethrow;
    }
  }

  Future<Challenge> sendChallenge(ChallengeCreate challenge) async {
    final result = await _api.sendChallenge(challenge);

    // Update cache
    await _cacheChallenge(result);

    return result;
  }

  Future<Challenge> acceptChallenge(int challengeId) async {
    final result = await _api.acceptChallenge(challengeId);

    // Update cache
    await _cacheChallenge(result);

    return result;
  }

  Future<Challenge> declineChallenge(int challengeId) async {
    final result = await _api.declineChallenge(challengeId);

    // Update cache
    await _cacheChallenge(result);

    return result;
  }

  Future<Challenge> completeChallenge(
    int challengeId,
    Map<String, dynamic> results,
  ) async {
    final result = await _api.completeChallenge(challengeId, results);

    // Update cache
    await _cacheChallenge(result);

    return result;
  }

  // Helper methods for caching
  Future<void> _cacheChallenges(List<Challenge> challenges) async {
    await _localStorage.setItem(
      'challenges',
      challenges.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _cachePendingChallenges(List<Challenge> challenges) async {
    await _localStorage.setItem(
      'pending_challenges',
      challenges.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _cacheChallenge(Challenge challenge) async {
    final challenges = await _getCachedChallenges();
    final index = challenges.indexWhere((c) => c.id == challenge.id);

    if (index >= 0) {
      challenges[index] = challenge;
    } else {
      challenges.add(challenge);
    }

    await _cacheChallenges(challenges);

    // Also update pending challenges if this is or was pending
    if (challenge.status == 'PENDING') {
      final pendingChallenges = await _getCachedChallenges(status: 'PENDING');
      final pendingIndex = pendingChallenges.indexWhere(
        (c) => c.id == challenge.id,
      );

      if (pendingIndex == -1) {
        pendingChallenges.add(challenge);
        await _cachePendingChallenges(pendingChallenges);
      }
    } else {
      // If status is not pending, remove from pending challenges if it exists there
      final pendingChallenges = await _getCachedChallenges(status: 'PENDING');
      final pendingIndex = pendingChallenges.indexWhere(
        (c) => c.id == challenge.id,
      );

      if (pendingIndex >= 0) {
        pendingChallenges.removeAt(pendingIndex);
        await _cachePendingChallenges(pendingChallenges);
      }
    }
  }

  Future<List<Challenge>> _getCachedChallenges({String? status}) async {
    // If specifically looking for pending challenges and we have that cache
    if (status == 'PENDING') {
      final pendingData = await _localStorage.getItem('pending_challenges');
      if (pendingData != null) {
        return (pendingData as List).map((e) => Challenge.fromJson(e)).toList();
      }
    }

    // Otherwise, get from the general challenges cache
    final data = await _localStorage.getItem('challenges');
    if (data == null) return [];

    List<Challenge> challenges = (data as List)
        .map((e) => Challenge.fromJson(e))
        .toList();

    // Apply status filter if provided
    if (status != null && status.isNotEmpty) {
      challenges = challenges.where((c) => c.status == status).toList();
    }

    return challenges;
  }

  Future<Challenge?> _getCachedChallenge(int challengeId) async {
    final challenges = await _getCachedChallenges();
    try {
      return challenges.firstWhere((c) => c.id == challengeId);
    } catch (e) {
      return null;
    }
  }
}
