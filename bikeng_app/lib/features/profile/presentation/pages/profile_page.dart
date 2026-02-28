import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User avatar + nickname section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '用户',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '感谢您使用避坑',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu items
            _MenuItem(
              icon: Icons.assignment,
              title: '我的举报',
              subtitle: '查看已提交的举报',
              onTap: () => context.push('/my-reports'),
            ),
            const Divider(height: 1, indent: 56),
            _MenuItem(
              icon: Icons.gavel,
              title: '我的申诉',
              subtitle: '查看申诉进度',
              onTap: () {
                // TODO: Navigate to my appeals list
              },
            ),
            const Divider(height: 1, indent: 56),
            _MenuItem(
              icon: Icons.add_circle_outline,
              title: '发起申诉',
              subtitle: '对误标记的账号提出申诉',
              onTap: () => context.push('/appeal'),
            ),
            const Divider(height: 1, indent: 56),
            _MenuItem(
              icon: Icons.notifications_outlined,
              title: '消息通知',
              subtitle: '查看系统通知',
              onTap: () => context.push('/alerts'),
            ),
            const Divider(height: 1, indent: 56),
            _MenuItem(
              icon: Icons.settings,
              title: '设置',
              subtitle: '账号设置与隐私',
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textHint,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}
