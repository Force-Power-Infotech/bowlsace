import '../../../api/api_client.dart';
import '../../../models/dashboard.dart';
import 'package:bowlsace/api/api_config.dart';

class DashboardApi {
  final ApiClient _apiClient;

  DashboardApi(this._apiClient);

  Future<DashboardMetrics> getDashboardMetrics(int userId) async {
    final response = await _apiClient.get('${ApiConfig.dashboard}/$userId');
    return DashboardMetrics.fromJson(response);
  }

  Future<DashboardMetrics> getUserDashboard() async {
    final response = await _apiClient.get('${ApiConfig.dashboard}/me');
    return DashboardMetrics.fromJson(response);
  }
}
