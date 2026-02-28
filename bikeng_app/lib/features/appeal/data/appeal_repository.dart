import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AppealRepository {
  final ApiClient apiClient;

  AppealRepository({required this.apiClient});

  /// Submit an appeal for a flagged account.
  Future<Map<String, dynamic>> submitAppeal(
      Map<String, dynamic> request) async {
    final response = await apiClient.post(
      ApiConstants.appeals,
      data: request,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get the status of a submitted appeal.
  Future<Map<String, dynamic>> getAppealStatus(String id) async {
    final response = await apiClient.get('${ApiConstants.appeals}/$id');
    return response.data as Map<String, dynamic>;
  }
}
