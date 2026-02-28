import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/comprehensive_risk_gauge.dart';
import '../../../../shared/widgets/score_breakdown_card.dart';
import '../../data/analysis_repository.dart';
import '../cubit/analysis_cubit.dart';
import '../cubit/analysis_state.dart';

class AnalysisResultPage extends StatelessWidget {
  final String sessionId;

  const AnalysisResultPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalysisCubit(
        analysisRepository: AnalysisRepository(
          apiClient: ApiClient(secureStorage: SecureStorage()),
        ),
      )..loadAnalysisResult(sessionId),
      child: _AnalysisResultContent(sessionId: sessionId),
    );
  }
}

class _AnalysisResultContent extends StatelessWidget {
  final String sessionId;

  const _AnalysisResultContent({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析报告')),
      body: BlocBuilder<AnalysisCubit, AnalysisState>(
        builder: (context, state) {
          if (state is AnalysisResultLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AnalysisError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.riskHigh),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AnalysisCubit>().loadAnalysisResult(sessionId),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          if (state is AnalysisResultLoaded) {
            return _buildResult(context, state.result);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildResult(BuildContext context, Map<String, dynamic> result) {
    final data = result['data'] ?? result;
    final session = data['session'] as Map<String, dynamic>? ?? {};
    final factors = (data['factors'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    final overallScore = (session['overall_score'] as num?)?.toDouble() ?? 0;
    final chatScore = (session['chat_score'] as num?)?.toDouble() ?? 0;
    final accountScore = (session['account_score'] as num?)?.toDouble() ?? 0;
    final transferScore = (session['transfer_score'] as num?)?.toDouble() ?? 0;
    final communityScore = (session['community_score'] as num?)?.toDouble() ?? 0;
    final confidence = (session['confidence'] as num?)?.toDouble() ?? 0;
    final summary = session['summary'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall score gauge
          ComprehensiveRiskGauge(
            score: overallScore,
            confidence: confidence,
          ),
          const SizedBox(height: 24),

          // Score breakdown cards
          ScoreBreakdownCard(
            title: '聊天话术分析',
            icon: Icons.chat_bubble_outline,
            score: chatScore,
            color: _scoreColor(chatScore),
          ),
          ScoreBreakdownCard(
            title: '账号风险分析',
            icon: Icons.person_outline,
            score: accountScore,
            color: _scoreColor(accountScore),
          ),
          ScoreBreakdownCard(
            title: '转账行为分析',
            icon: Icons.account_balance_wallet_outlined,
            score: transferScore,
            color: _scoreColor(transferScore),
          ),
          ScoreBreakdownCard(
            title: '社区举报评分',
            icon: Icons.people_outline,
            score: communityScore,
            color: _scoreColor(communityScore),
          ),
          const SizedBox(height: 16),

          // Risk factors
          if (factors.isNotEmpty) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('风险因子', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...factors.map((f) => _buildFactorItem(context, f)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Summary
          if (summary.isNotEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('分析摘要', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(summary, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.alertInfo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.alertInfo.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.alertInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '免责声明：本分析结果仅供参考，基于规则引擎和社区数据生成，不构成法律建议。如遇疑似诈骗，请及时报警。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.alertInfo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFactorItem(BuildContext context, Map<String, dynamic> factor) {
    final severity = factor['severity'] as String? ?? 'low';
    final factorType = factor['factor_type'] as String? ?? '';
    final factorValue = factor['factor_value'] as String? ?? '';
    final scoreImpact = (factor['score_impact'] as num?)?.toDouble() ?? 0;

    Color severityColor;
    String severityLabel;
    switch (severity) {
      case 'critical':
        severityColor = AppColors.riskHigh;
        severityLabel = '严重';
        break;
      case 'high':
        severityColor = AppColors.riskMedium;
        severityLabel = '高';
        break;
      case 'medium':
        severityColor = AppColors.riskLow;
        severityLabel = '中';
        break;
      default:
        severityColor = AppColors.riskSafe;
        severityLabel = '低';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              severityLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: severityColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(factorType, style: Theme.of(context).textTheme.titleSmall),
                if (factorValue.isNotEmpty)
                  Text(
                    factorValue,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '+${scoreImpact.toStringAsFixed(0)}',
            style: TextStyle(
              color: severityColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 70) return AppColors.riskHigh;
    if (score >= 40) return AppColors.riskMedium;
    if (score >= 20) return AppColors.riskLow;
    return AppColors.riskSafe;
  }
}
