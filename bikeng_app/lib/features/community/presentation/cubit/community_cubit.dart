import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/community_repository.dart';
import 'community_state.dart';

class CommunityCubit extends Cubit<CommunityState> {
  final CommunityRepository communityRepository;
  static const int _pageSize = 20;

  CommunityCubit({required this.communityRepository})
      : super(const CommunityInitial());

  /// Load posts for a given category. Pass null for all posts.
  Future<void> loadPosts({String? category}) async {
    emit(const CommunityLoading());
    try {
      final result = await communityRepository.getPosts(
        category: category,
        page: 1,
        pageSize: _pageSize,
      );
      final posts =
          (result['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];
      final total = result['total'] as int? ?? 0;

      emit(CommunityLoaded(
        posts: posts,
        total: total,
        currentPage: 1,
        category: category,
        hasMore: posts.length < total,
      ));
    } catch (e) {
      emit(CommunityError(message: '加载失败：${_parseError(e)}'));
    }
  }

  /// Load more posts (next page).
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! CommunityLoaded || !currentState.hasMore) return;

    try {
      final nextPage = currentState.currentPage + 1;
      final result = await communityRepository.getPosts(
        category: currentState.category,
        page: nextPage,
        pageSize: _pageSize,
      );
      final newPosts =
          (result['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];
      final allPosts = [...currentState.posts, ...newPosts];
      final total = result['total'] as int? ?? currentState.total;

      emit(currentState.copyWith(
        posts: allPosts,
        total: total,
        currentPage: nextPage,
        hasMore: allPosts.length < total,
      ));
    } catch (e) {
      // Keep existing data but emit error state briefly then return
      emit(const CommunityError(message: '加载更多失败'));
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '未知错误';
  }
}
