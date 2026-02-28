import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class CommunityRepository {
  final ApiClient apiClient;

  CommunityRepository({required this.apiClient});

  /// Get paginated list of posts, optionally filtered by category.
  Future<Map<String, dynamic>> getPosts({
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    final response = await apiClient.get(
      ApiConstants.posts,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get detail of a single post.
  Future<Map<String, dynamic>> getPostDetail(String id) async {
    final response = await apiClient.get('${ApiConstants.posts}/$id');
    return response.data as Map<String, dynamic>;
  }

  /// Create a new post.
  Future<Map<String, dynamic>> createPost(
      Map<String, dynamic> request) async {
    final response = await apiClient.post(
      ApiConstants.posts,
      data: request,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get comments for a post.
  Future<Map<String, dynamic>> getComments(
    String postId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '${ApiConstants.posts}/$postId/comments',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Add a comment to a post.
  Future<Map<String, dynamic>> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    final data = <String, dynamic>{
      'content': content,
    };
    if (parentId != null) {
      data['parent_id'] = parentId;
    }
    final response = await apiClient.post(
      '${ApiConstants.posts}/$postId/comments',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Like a post.
  Future<void> likePost(String postId) async {
    await apiClient.post('${ApiConstants.posts}/$postId/like');
  }

  /// Unlike a post.
  Future<void> unlikePost(String postId) async {
    await apiClient.delete('${ApiConstants.posts}/$postId/like');
  }
}
