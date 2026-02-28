import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/report_repository.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportCubit(
        reportRepository: ReportRepository(
          apiClient: ApiClient(secureStorage: SecureStorage()),
        ),
      )..loadMyReports(),
      child: const _MyReportsContent(),
    );
  }
}

class _MyReportsContent extends StatelessWidget {
  const _MyReportsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的举报'),
      ),
      body: BlocBuilder<ReportCubit, ReportState>(
        builder: (context, state) {
          if (state is ReportListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportError) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<ReportCubit>().loadMyReports(),
            );
          }
          if (state is ReportListLoaded) {
            if (state.reports.isEmpty) {
              return const EmptyState(
                icon: Icons.assignment_outlined,
                title: '暂无举报记录',
                subtitle: '您还没有提交过举报',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.reports.length,
              itemBuilder: (context, index) {
                final report = state.reports[index];
                return _ReportListItem(report: report);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final Map<String, dynamic> report;

  const _ReportListItem({required this.report});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.riskLow;
      case 'reviewing':
        return AppColors.alertInfo;
      case 'confirmed':
        return AppColors.riskSafe;
      case 'rejected':
        return AppColors.riskHigh;
      default:
        return AppColors.textHint;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '待审核';
      case 'reviewing':
        return '审核中';
      case 'confirmed':
        return '已确认';
      case 'rejected':
        return '已驳回';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = report['id'] as String? ?? '';
    final accountType = report['account_type'] as String? ?? '';
    final accountValue = report['account_value'] as String? ?? '';
    final scamType = report['scam_type'] as String? ?? '';
    final status = report['status'] as String? ?? 'pending';
    final createdAt = report['created_at'] as String? ?? '';

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _statusColor(status).withOpacity(0.15),
          child: Icon(
            Icons.report,
            color: _statusColor(status),
            size: 22,
          ),
        ),
        title: Text(
          '$accountType: $accountValue',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(scamType),
            const SizedBox(height: 4),
            Text(
              createdAt,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _statusLabel(status),
            style: TextStyle(
              fontSize: 12,
              color: _statusColor(status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => context.push('/report/$id'),
      ),
    );
  }
}
