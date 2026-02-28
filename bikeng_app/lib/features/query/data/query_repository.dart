import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class QueryRepository {
  final ApiClient apiClient;

  QueryRepository({required this.apiClient});

  /// Query a single account for fraud risk.
  Future<Map<String, dynamic>> queryAccount(
    String accountType,
    String accountValue,
  ) async {
    final response = await apiClient.post(
      ApiConstants.query,
      data: {
        'account_type': accountType,
        'account_value': accountValue,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Batch query multiple accounts.
  Future<List<Map<String, dynamic>>> queryBatch(
    List<Map<String, String>> queries,
  ) async {
    final response = await apiClient.post(
      ApiConstants.queryBatch,
      data: {'queries': queries},
    );
    final dataList = response.data['results'] as List<dynamic>;
    return dataList.cast<Map<String, dynamic>>();
  }

  /// Extract account information from a screenshot using OCR.
  Future<Map<String, dynamic>> ocrExtract(String imageBase64) async {
    final response = await apiClient.post(
      ApiConstants.ocrExtract,
      data: {'image': imageBase64},
    );
    return response.data as Map<String, dynamic>;
  }
}
