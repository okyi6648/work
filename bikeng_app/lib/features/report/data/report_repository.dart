import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ReportRepository {
  final ApiClient apiClient;

  ReportRepository({required this.apiClient});

  /// Submit a new fraud report.
  Future<Map<String, dynamic>> submitReport(
      Map<String, dynamic> request) async {
    final response = await apiClient.post(
      ApiConstants.reports,
      data: request,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get paginated list of user's own reports.
  Future<Map<String, dynamic>> getMyReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      ApiConstants.myReports,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get detail of a specific report.
  Future<Map<String, dynamic>> getReportDetail(String id) async {
    final response = await apiClient.get('${ApiConstants.reports}/$id');
    return response.data as Map<String, dynamic>;
  }

  /// Get a presigned URL for uploading evidence files.
  Future<Map<String, dynamic>> getPresignedUrl(String fileExt) async {
    final response = await apiClient.post(
      ApiConstants.uploadPresign,
      data: {'file_ext': fileExt},
    );
    return response.data as Map<String, dynamic>;
  }
}
