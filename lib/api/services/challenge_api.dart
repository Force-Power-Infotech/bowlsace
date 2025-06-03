import '../../../api/api_client.dart';
import '../../../models/challenge.dart';
import 'package:bowlsace/api/api_config.dart';

class ChallengeApi {
  final ApiClient _apiClient;

  ChallengeApi(this._apiClient);

  Future<List<Challenge>> getChallenges({
    String? status,
    int limit = 10,
  }) async {
    String endpoint = ApiConfig.challenges;
    List<String> queryParams = [];

    if (status != null && status.isNotEmpty) {
      queryParams.add('status=$status');
    }

    if (limit > 0) {
      queryParams.add('limit=$limit');
    }

    if (queryParams.isNotEmpty) {
      endpoint = '$endpoint?${queryParams.join('&')}';
    }

    final response = await _apiClient.get(endpoint);
    return (response as List).map((item) => Challenge.fromJson(item)).toList();
  }

  Future<Challenge> getChallenge(int challengeId) async {
    final response = await _apiClient.get(
      '${ApiConfig.challenges}/$challengeId',
    );
    return Challenge.fromJson(response);
  }

  Future<List<Challenge>> getPendingChallenges() async {
    return getChallenges(status: 'PENDING');
  }

  Future<Challenge> sendChallenge(ChallengeCreate challenge) async {
    final response = await _apiClient.post(
      '${ApiConfig.challenges}/send',
      challenge.toJson(),
    );
    return Challenge.fromJson(response);
  }

  Future<Challenge> acceptChallenge(int challengeId) async {
    final endpoint = ApiConfig.acceptChallenge.replaceAll(
      '{id}',
      challengeId.toString(),
    );
    final response = await _apiClient.put(endpoint, {});
    return Challenge.fromJson(response);
  }

  Future<Challenge> declineChallenge(int challengeId) async {
    final response = await _apiClient.put(
      '${ApiConfig.challenges}/$challengeId/decline',
      {},
    );
    return Challenge.fromJson(response);
  }

  Future<Challenge> completeChallenge(
    int challengeId,
    Map<String, dynamic> results,
  ) async {
    final response = await _apiClient.put(
      '${ApiConfig.challenges}/$challengeId',
      results,
    );
    return Challenge.fromJson(response);
  }
}
