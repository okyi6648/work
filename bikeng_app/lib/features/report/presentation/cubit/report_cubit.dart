import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/report_repository.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository reportRepository;

  ReportCubit({required this.reportRepository}) : super(const ReportInitial());

  /// Submit a new fraud report.
  Future<void> submitReport(Map<String, dynamic> data) async {
    emit(const ReportSubmitting());
    try {
      final result = await reportRepository.submitReport(data);
      emit(ReportSubmitted(report: result));
    } catch (e) {
      emit(ReportError(message: '提交举报失败：${_parseError(e)}'));
    }
  }

  /// Load user's own reports for a given page.
  Future<void> loadMyReports({int page = 1}) async {
    emit(const ReportListLoading());
    try {
      final result = await reportRepository.getMyReports(page: page);
      final reports =
          (result['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];
      final total = result['total'] as int? ?? 0;
      emit(ReportListLoaded(
        reports: reports,
        total: total,
        currentPage: page,
      ));
    } catch (e) {
      emit(ReportError(message: '加载举报列表失败：${_parseError(e)}'));
    }
  }

  /// Reset to initial state.
  void reset() {
    emit(const ReportInitial());
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '未知错误';
  }
}
