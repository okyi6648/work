import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/analysis_repository.dart';
import 'analysis_state.dart';

class AnalysisCubit extends Cubit<AnalysisState> {
  final AnalysisRepository analysisRepository;

  AnalysisCubit({required this.analysisRepository})
      : super(const AnalysisInitial());

  /// Submit images for comprehensive analysis.
  Future<void> submitAnalysis(List<Map<String, String>> images) async {
    emit(const AnalysisSubmitting());
    try {
      final result = await analysisRepository.submitAnalysis(images);
      emit(AnalysisCompleted(result: result));
    } catch (e) {
      emit(AnalysisError(message: '分析失败：${_parseError(e)}'));
    }
  }

  /// Load a specific analysis result.
  Future<void> loadAnalysisResult(String id) async {
    emit(const AnalysisResultLoading());
    try {
      final result = await analysisRepository.getAnalysisResult(id);
      emit(AnalysisResultLoaded(result: result));
    } catch (e) {
      emit(AnalysisError(message: '加载分析结果失败：${_parseError(e)}'));
    }
  }

  /// Load analysis history.
  Future<void> loadHistory({int page = 1}) async {
    emit(const AnalysisHistoryLoading());
    try {
      final result = await analysisRepository.getMyAnalyses(page: page);
      final sessions =
          (result['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];
      final total = result['total'] as int? ?? 0;
      emit(AnalysisHistoryLoaded(
        sessions: sessions,
        total: total,
        currentPage: page,
      ));
    } catch (e) {
      emit(AnalysisError(message: '加载历史记录失败：${_parseError(e)}'));
    }
  }

  /// Reset to initial state.
  void reset() {
    emit(const AnalysisInitial());
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '未知错误';
  }
}
