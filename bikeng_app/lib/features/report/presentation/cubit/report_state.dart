import 'package:equatable/equatable.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportSubmitting extends ReportState {
  const ReportSubmitting();
}

class ReportSubmitted extends ReportState {
  final Map<String, dynamic> report;

  const ReportSubmitted({required this.report});

  @override
  List<Object?> get props => [report];
}

class ReportListLoading extends ReportState {
  const ReportListLoading();
}

class ReportListLoaded extends ReportState {
  final List<Map<String, dynamic>> reports;
  final int total;
  final int currentPage;

  const ReportListLoaded({
    required this.reports,
    required this.total,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [reports, total, currentPage];
}

class ReportError extends ReportState {
  final String message;

  const ReportError({required this.message});

  @override
  List<Object?> get props => [message];
}
