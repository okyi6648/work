import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../alerts/data/alert_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  late final AlertRepository _alertRepository;
  List<Map<String, dynamic>> _latestAlerts = [];
  bool _alertsLoading = true;

  @override
  void initState() {
    super.initState();
    _alertRepository = AlertRepository(
      apiClient: ApiClient(secureStorage: SecureStorage()),
    );
    _loadAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _alertRepository.getLatestAlerts(limit: 5);
      if (mounted) {
        setState(() {
          _latestAlerts = alerts;
          _alertsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _alertsLoading = false);
    }
  }

  void _quickQuery() {
    final value = _searchController.text.trim();
    if (value.isEmpty) return;
    // Navigate to query tab -- could also directly call the query API
    context.go('/query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, size: 24),
            SizedBox(width: 8),
            Text('避坑'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/alerts'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primary,
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _quickQuery(),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '输入账号快速查询...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _quickQuery,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Alert banner carousel
              if (_latestAlerts.isNotEmpty) _AlertBanner(alerts: _latestAlerts),

              // Quick action cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '快捷操作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.report,
                            label: '举报',
                            color: AppColors.riskHigh,
                            onTap: () => context.push('/report'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.search,
                            label: '查询',
                            color: AppColors.primary,
                            onTap: () => context.go('/query'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.camera_alt,
                            label: '识别',
                            color: AppColors.secondary,
                            onTap: () => context.go('/query'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Latest alerts section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '最新预警',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/alerts'),
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
              ),

              if (_alertsLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_latestAlerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      '暂无预警信息',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                )
              else
                ..._latestAlerts.map(
                  (alert) => _AlertListItem(alert: alert),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const _AlertBanner({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: PageView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final severity = alert['severity'] as String? ?? 'info';
          final title = alert['title'] as String? ?? '';
          final content = alert['content'] as String? ?? '';

          Color bgColor;
          switch (severity) {
            case 'critical':
              bgColor = AppColors.alertCritical;
              break;
            case 'warning':
              bgColor = AppColors.alertWarning;
              break;
            default:
              bgColor = AppColors.alertInfo;
          }

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bgColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: bgColor, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: bgColor,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertListItem extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertListItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity'] as String? ?? 'info';
    final title = alert['title'] as String? ?? '';
    final createdAt = alert['created_at'] as String? ?? '';

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = AppColors.alertCritical;
        break;
      case 'warning':
        severityColor = AppColors.alertWarning;
        break;
      default:
        severityColor = AppColors.alertInfo;
    }

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.circle,
          size: 10,
          color: severityColor,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          createdAt,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
        dense: true,
        onTap: () => context.push('/alerts'),
      ),
    );
  }
}
