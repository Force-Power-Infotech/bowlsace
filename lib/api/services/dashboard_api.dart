import '../../../api/api_client.dart';
import '../../../models/dashboard.dart';
import 'package:bowlsace/api/api_config.dart';

class DashboardApi {
  final ApiClient _apiClient;

  DashboardApi(this._apiClient);

  Future<DashboardMetrics> getDashboardMetrics(int userId) async {
    final response = await _apiClient.get('${ApiConfig.dashboard}/$userId');

    if (response.containsKey('data')) {
      return DashboardMetrics.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    } else {
      return DashboardMetrics.fromJson(response);
    }
  }

  Future<DashboardMetrics> getUserDashboard() async {
    final response = await _apiClient.get('${ApiConfig.dashboard}/me');

    if (response.containsKey('data')) {
      return DashboardMetrics.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    } else {
      return DashboardMetrics.fromJson(response);
    }
  }
}
