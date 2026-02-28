import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/widgets/risk_indicator.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/query_repository.dart';
import '../cubit/query_cubit.dart';
import '../cubit/query_state.dart';

class QueryPage extends StatelessWidget {
  const QueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QueryCubit(
        queryRepository: QueryRepository(
          apiClient: ApiClient(secureStorage: SecureStorage()),
        ),
      ),
      child: const _QueryPageContent(),
    );
  }
}

class _QueryPageContent extends StatelessWidget {
  const _QueryPageContent();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('查询'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: '手动输入', icon: Icon(Icons.keyboard, size: 20)),
              Tab(text: '截图识别', icon: Icon(Icons.camera_alt, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ManualQueryTab(),
            _OcrQueryTab(),
          ],
        ),
      ),
    );
  }
}

class _ManualQueryTab extends StatefulWidget {
  const _ManualQueryTab();

  @override
  State<_ManualQueryTab> createState() => _ManualQueryTabState();
}

class _ManualQueryTabState extends State<_ManualQueryTab> {
  final _controller = TextEditingController();
  String _selectedType = 'phone';

  final _accountTypes = {
    'phone': '手机号',
    'qq': 'QQ',
    'wechat': '微信',
    'alipay': '支付宝',
    'bank_card': '银行卡',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performQuery() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入要查询的账号')),
      );
      return;
    }
    context.read<QueryCubit>().queryAccount(_selectedType, value);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Account type dropdown
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: '账号类型',
              prefixIcon: Icon(Icons.category),
            ),
            items: _accountTypes.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 16),

          // Account value input
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: '账号/号码',
              hintText: '请输入要查询的${_accountTypes[_selectedType]}',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _controller.clear(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Query button
          ElevatedButton.icon(
            onPressed: _performQuery,
            icon: const Icon(Icons.search),
            label: const Text('查询'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 32),

          // Result area
          BlocBuilder<QueryCubit, QueryState>(
            builder: (context, state) {
              if (state is QueryLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is QueryError) {
                return ErrorView(
                  message: state.message,
                  onRetry: _performQuery,
                );
              }
              if (state is QuerySuccess) {
                return _QueryResultCard(result: state.result);
              }
              return const EmptyState(
                icon: Icons.search,
                title: '输入账号进行查询',
                subtitle: '支持手机号、QQ、微信、支付宝、银行卡号查询',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QueryResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _QueryResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final riskScore = (result['risk_score'] as num?)?.toDouble() ?? 0;
    final riskLevel = result['risk_level'] as String? ?? 'safe';
    final accountType = result['account_type'] as String? ?? '';
    final accountValue = result['account_value'] as String? ?? '';
    final reportCount = result['report_count'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RiskIndicator(
              riskScore: riskScore,
              riskLevel: riskLevel,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _InfoRow(label: '账号类型', value: accountType),
            _InfoRow(label: '账号', value: accountValue),
            _InfoRow(label: '举报次数', value: '$reportCount'),
            const SizedBox(height: 16),
            const Text(
              '免责声明：查询结果仅供参考，不作为法律依据。',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to report form
              },
              icon: const Icon(Icons.report, size: 18),
              label: const Text('举报此账号'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.riskHigh,
                side: const BorderSide(color: AppColors.riskHigh),
              ),
            ),
          ],
        ),
      ),
    );
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OcrQueryTab extends StatefulWidget {
  const _OcrQueryTab();

  @override
  State<_OcrQueryTab> createState() => _OcrQueryTabState();
}

class _OcrQueryTabState extends State<_OcrQueryTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);

      if (mounted) {
        context.read<QueryCubit>().extractFromImage(base64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片选取失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Pick image buttons
          Row(
            children: [
              Expanded(
                child: _PickButton(
                  icon: Icons.camera_alt,
                  label: '拍照',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PickButton(
                  icon: Icons.photo_library,
                  label: '从相册选择',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Results
          BlocBuilder<QueryCubit, QueryState>(
            builder: (context, state) {
              if (state is QueryLoading) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '正在识别中...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              if (state is QueryError) {
                return ErrorView(message: state.message);
              }
              if (state is QueryOcrSuccess) {
                if (state.extractedAccounts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.image_not_supported,
                    title: '未识别到账号信息',
                    subtitle: '请确保截图中包含清晰的账号信息',
                  );
                }
                return _OcrResultList(accounts: state.extractedAccounts);
              }
              return const EmptyState(
                icon: Icons.camera_alt,
                title: '上传聊天截图',
                subtitle: '自动识别截图中的账号信息并查询风险',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrResultList extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;

  const _OcrResultList({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '识别到 ${accounts.length} 个账号',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...accounts.map((account) {
          final type = account['type'] as String? ?? '';
          final value = account['value'] as String? ?? '';
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(
                  _iconForType(type),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(value),
              subtitle: Text(type),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.read<QueryCubit>().queryAccount(type, value);
              },
            ),
          );
        }),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'qq':
        return Icons.chat;
      case 'wechat':
        return Icons.message;
      case 'alipay':
        return Icons.account_balance_wallet;
      case 'bank_card':
        return Icons.credit_card;
      default:
        return Icons.account_circle;
    }
  }
}
