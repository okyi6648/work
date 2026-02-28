import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/report_repository.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late final ReportRepository _repository;
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ReportRepository(
      apiClient: ApiClient(secureStorage: SecureStorage()),
    );
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.getReportDetail(widget.reportId);
      setState(() {
        _report = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败';
        _isLoading = false;
      });
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('举报详情'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadDetail);
    }
    if (_report == null) {
      return const ErrorView(message: '数据不存在');
    }

    final report = _report!;
    final status = report['status'] as String? ?? 'pending';
    final accountType = report['account_type'] as String? ?? '';
    final accountValue = report['account_value'] as String? ?? '';
    final scamType = report['scam_type'] as String? ?? '';
    final description = report['description'] as String? ?? '';
    final lossAmount = report['loss_amount'];
    final incidentDate = report['incident_date'] as String? ?? '';
    final evidenceUrls =
        (report['evidence_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final createdAt = report['created_at'] as String? ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _statusColor(status).withOpacity(0.08),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _statusColor(status),
                ),
                const SizedBox(width: 8),
                Text(
                  '状态: ${_statusLabel(status)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ],
            ),
          ),

          // Account info section
          _Section(
            title: '账号信息',
            children: [
              _DetailRow(label: '账号类型', value: accountType),
              _DetailRow(label: '账号', value: accountValue),
            ],
          ),

          // Scam details section
          _Section(
            title: '诈骗详情',
            children: [
              _DetailRow(label: '诈骗类型', value: scamType),
              _DetailRow(label: '详细描述', value: description),
              if (lossAmount != null)
                _DetailRow(label: '损失金额', value: '$lossAmount 元'),
              if (incidentDate.isNotEmpty)
                _DetailRow(label: '受骗日期', value: incidentDate),
            ],
          ),

          // Evidence section
          if (evidenceUrls.isNotEmpty)
            _Section(
              title: '证据材料',
              children: [
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: evidenceUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: evidenceUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.background,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.background,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          // Submission info
          _Section(
            title: '提交信息',
            children: [
              _DetailRow(label: '提交时间', value: createdAt),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
