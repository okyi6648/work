import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/query_repository.dart';
import 'query_state.dart';

class QueryCubit extends Cubit<QueryState> {
  final QueryRepository queryRepository;

  QueryCubit({required this.queryRepository}) : super(const QueryInitial());

  /// Query a single account.
  Future<void> queryAccount(String type, String value) async {
    emit(const QueryLoading());
    try {
      final result = await queryRepository.queryAccount(type, value);
      emit(QuerySuccess(result: result));
    } catch (e) {
      emit(QueryError(message: '查询失败：${_parseError(e)}'));
    }
  }

  /// Extract accounts from an image via OCR.
  Future<void> extractFromImage(String base64) async {
    emit(const QueryLoading());
    try {
      final result = await queryRepository.ocrExtract(base64);
      final accounts = (result['accounts'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      emit(QueryOcrSuccess(extractedAccounts: accounts));
    } catch (e) {
      emit(QueryError(message: '识别失败：${_parseError(e)}'));
    }
  }

  /// Reset to initial state.
  void reset() {
    emit(const QueryInitial());
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '未知错误';
  }
}
