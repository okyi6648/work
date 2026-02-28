import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/appeal_repository.dart';

class AppealStatusPage extends StatefulWidget {
  final String appealId;

  const AppealStatusPage({super.key, required this.appealId});

  @override
  State<AppealStatusPage> createState() => _AppealStatusPageState();
}

class _AppealStatusPageState extends State<AppealStatusPage> {
  late final AppealRepository _repository;
  Map<String, dynamic>? _appeal;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = AppealRepository(
      apiClient: ApiClient(secureStorage: SecureStorage()),
    );
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.getAppealStatus(widget.appealId);
      setState(() {
        _appeal = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('申诉进度'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadStatus);
    }
    if (_appeal == null) {
      return const ErrorView(message: '申诉不存在');
    }

    final appeal = _appeal!;
    final status = appeal['status'] as String? ?? 'pending';
    final accountId = appeal['account_id'] as String? ?? '';
    final reason = appeal['reason'] as String? ?? '';
    final adminNote = appeal['admin_note'] as String? ?? '';
    final createdAt = appeal['created_at'] as String? ?? '';

    final steps = _buildSteps(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appeal info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '申诉信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 20),
                  _InfoRow(label: '账号ID', value: accountId),
                  _InfoRow(label: '申诉理由', value: reason),
                  _InfoRow(label: '提交时间', value: createdAt),
                  if (adminNote.isNotEmpty)
                    _InfoRow(label: '审核备注', value: adminNote),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress timeline
          const Text(
            '处理进度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Stepper(
            currentStep: _currentStepIndex(status),
            physics: const NeverScrollableScrollPhysics(),
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: steps,
          ),
        ],
      ),
    );
  }

  int _currentStepIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'reviewing':
        return 1;
      case 'approved':
        return 2;
      case 'rejected':
        return 2;
      default:
        return 0;
    }
  }

  List<Step> _buildSteps(String status) {
    return [
      const Step(
        title: Text('已提交'),
        subtitle: Text('申诉已成功提交'),
        content: SizedBox.shrink(),
        isActive: true,
        state: StepState.complete,
      ),
      Step(
        title: const Text('审核中'),
        subtitle: const Text('工作人员正在审核'),
        content: const SizedBox.shrink(),
        isActive: status == 'reviewing' ||
            status == 'approved' ||
            status == 'rejected',
        state: (status == 'approved' || status == 'rejected')
            ? StepState.complete
            : status == 'reviewing'
                ? StepState.indexed
                : StepState.disabled,
      ),
      Step(
        title: Text(
          status == 'rejected' ? '已驳回' : '已完成',
        ),
        subtitle: Text(
          status == 'approved'
              ? '申诉已通过，标记已移除'
              : status == 'rejected'
                  ? '申诉未通过'
                  : '等待审核结果',
        ),
        content: const SizedBox.shrink(),
        isActive: status == 'approved' || status == 'rejected',
        state: status == 'approved'
            ? StepState.complete
            : status == 'rejected'
                ? StepState.error
                : StepState.disabled,
      ),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

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
