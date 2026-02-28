import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/analysis_repository.dart';
import '../cubit/analysis_cubit.dart';
import '../cubit/analysis_state.dart';

class AnalysisHistoryPage extends StatelessWidget {
  const AnalysisHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalysisCubit(
        analysisRepository: AnalysisRepository(
          apiClient: ApiClient(secureStorage: SecureStorage()),
        ),
      )..loadHistory(),
      child: const _AnalysisHistoryContent(),
    );
  }
}

class _AnalysisHistoryContent extends StatelessWidget {
  const _AnalysisHistoryContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析历史')),
      body: BlocBuilder<AnalysisCubit, AnalysisState>(
        builder: (context, state) {
          if (state is AnalysisHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AnalysisError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AnalysisCubit>().loadHistory(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          if (state is AnalysisHistoryLoaded) {
            if (state.sessions.isEmpty) {
              return const EmptyState(
                icon: Icons.analytics_outlined,
                title: '暂无分析记录',
                subtitle: '提交综合分析后将在这里显示',
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<AnalysisCubit>().loadHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.sessions.length,
                itemBuilder: (context, index) =>
                    _buildSessionItem(context, state.sessions[index]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, Map<String, dynamic> session) {
    final id = session['id']?.toString() ?? '';
    final overallScore = (session['overall_score'] as num?)?.toDouble() ?? 0;
    final status = session['status'] as String? ?? '';
    final createdAt = session['created_at'] as String? ?? '';

    Color scoreColor;
    String riskLabel;
    if (overallScore >= 70) {
      scoreColor = AppColors.riskHigh;
      riskLabel = '高风险';
    } else if (overallScore >= 40) {
      scoreColor = AppColors.riskMedium;
      riskLabel = '中风险';
    } else {
      scoreColor = AppColors.riskSafe;
      riskLabel = '低风险';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/analysis/result/$id'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withOpacity(0.1),
                  border: Border.all(color: scoreColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${overallScore.toInt()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            riskLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scoreColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (status == 'completed')
                          const Icon(Icons.check_circle, size: 16, color: AppColors.riskSafe),
                        if (status == 'processing')
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt.length >= 16 ? createdAt.substring(0, 16) : createdAt,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
