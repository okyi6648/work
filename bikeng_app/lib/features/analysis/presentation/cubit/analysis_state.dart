import 'package:equatable/equatable.dart';

abstract class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object?> get props => [];
}

class AnalysisInitial extends AnalysisState {
  const AnalysisInitial();
}

class AnalysisSubmitting extends AnalysisState {
  const AnalysisSubmitting();
}

class AnalysisCompleted extends AnalysisState {
  final Map<String, dynamic> result;

  const AnalysisCompleted({required this.result});

  @override
  List<Object?> get props => [result];
}

class AnalysisResultLoading extends AnalysisState {
  const AnalysisResultLoading();
}

class AnalysisResultLoaded extends AnalysisState {
  final Map<String, dynamic> result;

  const AnalysisResultLoaded({required this.result});

  @override
  List<Object?> get props => [result];
}

class AnalysisHistoryLoading extends AnalysisState {
  const AnalysisHistoryLoading();
}

class AnalysisHistoryLoaded extends AnalysisState {
  final List<Map<String, dynamic>> sessions;
  final int total;
  final int currentPage;

  const AnalysisHistoryLoaded({
    required this.sessions,
    required this.total,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [sessions, total, currentPage];
}

class AnalysisError extends AnalysisState {
  final String message;

  const AnalysisError({required this.message});

  @override
  List<Object?> get props => [message];
}
