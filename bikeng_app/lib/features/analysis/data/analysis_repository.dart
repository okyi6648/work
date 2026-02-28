import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AnalysisRepository {
  final ApiClient apiClient;

  AnalysisRepository({required this.apiClient});

  /// Submit images for comprehensive analysis.
  Future<Map<String, dynamic>> submitAnalysis(
      List<Map<String, String>> images) async {
    final response = await apiClient.post(
      ApiConstants.analysisComprehensive,
      data: {'images': images},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get a specific analysis result by ID.
  Future<Map<String, dynamic>> getAnalysisResult(String id) async {
    final response = await apiClient.get('${ApiConstants.analysis}/$id');
    return response.data as Map<String, dynamic>;
  }

  /// Get paginated list of user's analysis history.
  Future<Map<String, dynamic>> getMyAnalyses({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      ApiConstants.analysisMine,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get a presigned URL for uploading images.
  Future<Map<String, dynamic>> getPresignedUrl(String fileExt) async {
    final response = await apiClient.post(
      ApiConstants.uploadPresign,
      data: {'file_ext': fileExt},
    );
    return response.data as Map<String, dynamic>;
  }
}
