import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nicknameController = TextEditingController(text: '用户');
  bool _isEditingNickname = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _toggleNicknameEdit() {
    setState(() => _isEditingNickname = !_isEditingNickname);
  }

  void _saveNickname() {
    // TODO: Save to backend
    setState(() => _isEditingNickname = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('昵称已更新')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.riskHigh,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Nickname
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: const Text('修改昵称'),
            subtitle: _isEditingNickname
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check,
                            color: AppColors.riskSafe, size: 20),
                        onPressed: _saveNickname,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textHint, size: 20),
                        onPressed: _toggleNicknameEdit,
                      ),
                    ],
                  )
                : Text(
                    _nicknameController.text,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
            trailing: _isEditingNickname
                ? null
                : const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: _isEditingNickname ? null : _toggleNicknameEdit,
          ),

          const Divider(height: 1),

          // Privacy policy
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.primary),
            title: const Text('隐私政策'),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: () {
              // TODO: Open privacy policy page
            },
          ),

          const Divider(height: 1),

          // User agreement
          ListTile(
            leading:
                const Icon(Icons.article_outlined, color: AppColors.primary),
            title: const Text('用户协议'),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: () {
              // TODO: Open user agreement page
            },
          ),

          const Divider(height: 1),

          // About
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.primary),
            title: const Text('关于避坑'),
            subtitle: const Text(
              'v1.0.0',
              style: TextStyle(color: AppColors.textHint),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '避坑',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                children: [
                  const Text('避坑 - 反诈防骗助手'),
                  const SizedBox(height: 8),
                  const Text(
                    '帮助用户识别和防范网络诈骗，共建安全网络环境。',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.riskHigh,
                side: const BorderSide(color: AppColors.riskHigh),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
