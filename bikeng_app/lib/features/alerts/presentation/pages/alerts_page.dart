import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/alert_repository.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late final AlertRepository _repository;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = AlertRepository(
      apiClient: ApiClient(secureStorage: SecureStorage()),
    );
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.getAlerts();
      final items =
          (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _alerts = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败';
        _isLoading = false;
      });
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'info':
        return AppColors.alertInfo;
      case 'warning':
        return AppColors.alertWarning;
      case 'critical':
        return AppColors.alertCritical;
      default:
        return AppColors.textHint;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_amber;
      case 'critical':
        return Icons.error_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _severityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'info':
        return '提醒';
      case 'warning':
        return '警告';
      case 'critical':
        return '紧急';
      default:
        return severity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预警信息'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadAlerts);
    }
    if (_alerts.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off_outlined,
        title: '暂无预警信息',
        subtitle: '目前没有新的预警通知',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final severity = alert['severity'] as String? ?? 'info';
          final title = alert['title'] as String? ?? '';
          final content = alert['content'] as String? ?? '';
          final createdAt = alert['created_at'] as String? ?? '';

          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _severityColor(severity).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _severityIcon(severity),
                  color: _severityColor(severity),
                  size: 24,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _severityColor(severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _severityLabel(severity),
                      style: TextStyle(
                        fontSize: 11,
                        color: _severityColor(severity),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    createdAt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
