import 'package:equatable/equatable.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {
  const CommunityInitial();
}

class CommunityLoading extends CommunityState {
  const CommunityLoading();
}

class CommunityLoaded extends CommunityState {
  final List<Map<String, dynamic>> posts;
  final int total;
  final int currentPage;
  final String? category;
  final bool hasMore;

  const CommunityLoaded({
    required this.posts,
    required this.total,
    required this.currentPage,
    this.category,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [posts, total, currentPage, category, hasMore];

  CommunityLoaded copyWith({
    List<Map<String, dynamic>>? posts,
    int? total,
    int? currentPage,
    String? category,
    bool? hasMore,
  }) {
    return CommunityLoaded(
      posts: posts ?? this.posts,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      category: category ?? this.category,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class CommunityError extends CommunityState {
  final String message;

  const CommunityError({required this.message});

  @override
  List<Object?> get props => [message];
}
