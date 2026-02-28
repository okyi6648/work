import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/risk_indicator.dart';

class QueryResultPage extends StatelessWidget {
  final Map<String, dynamic> result;

  const QueryResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final riskScore = (result['risk_score'] as num?)?.toDouble() ?? 0;
    final riskLevel = result['risk_level'] as String? ?? 'safe';
    final accountType = result['account_type'] as String? ?? '';
    final accountValue = result['account_value'] as String? ?? '';
    final reportCount = result['report_count'] as int? ?? 0;
    final reportTypes =
        (result['report_types'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('查询结果'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Risk score header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.riskColor(riskLevel).withOpacity(0.08),
              ),
              child: Column(
                children: [
                  RiskIndicator(
                    riskScore: riskScore,
                    riskLevel: riskLevel,
                    size: 120,
                  ),
                ],
              ),
            ),

            // Account info card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '账号信息',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    _DetailRow(label: '账号类型', value: _typeLabel(accountType)),
                    _DetailRow(label: '账号', value: accountValue),
                  ],
                ),
              ),
            ),

            // Report summary card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '举报摘要',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    _DetailRow(label: '举报次数', value: '$reportCount'),
                    if (reportTypes.isNotEmpty)
                      _DetailRow(
                        label: '举报类型',
                        value: reportTypes.join('、'),
                      ),
                  ],
                ),
              ),
            ),

            // Disclaimer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertInfo.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.alertInfo.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.alertInfo,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '免责声明：本查询结果基于用户举报数据生成，仅供参考，不构成任何法律意见或判断依据。如有疑问请联系有关部门。',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Report button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/report'),
                  icon: const Icon(Icons.report),
                  label: const Text('举报此账号'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.riskHigh,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    const labels = {
      'phone': '手机号',
      'qq': 'QQ',
      'wechat': '微信',
      'alipay': '支付宝',
      'bank_card': '银行卡',
    };
    return labels[type] ?? type;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
