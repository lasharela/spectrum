import '../../../shared/api/api_client.dart';
import '../domain/dashboard.dart';

class DashboardRepository {
  final ApiClient _api;

  DashboardRepository(this._api);

  Future<DashboardData> getDashboard() async {
    final response = await _api.get('/api/dashboard');
    final data = response.data as Map<String, dynamic>;
    return DashboardData.fromJson(data);
  }
}
