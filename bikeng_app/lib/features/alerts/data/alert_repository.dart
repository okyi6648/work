import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AlertRepository {
  final ApiClient apiClient;

  AlertRepository({required this.apiClient});

  /// Get paginated list of alerts.
  Future<Map<String, dynamic>> getAlerts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      ApiConstants.alerts,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get latest alerts with an optional limit.
  Future<List<Map<String, dynamic>>> getLatestAlerts({int limit = 5}) async {
    final response = await apiClient.get(
      ApiConstants.alertsLatest,
      queryParameters: {'limit': limit},
    );
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }
}
