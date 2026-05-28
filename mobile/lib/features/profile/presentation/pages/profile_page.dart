import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SfinityApp.auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        CircleAvatar(
          radius: 40,
          child: Text((user?['name']?.toString() ?? 'U')[0].toUpperCase()),
        ),
        const SizedBox(height: 12),
        Text(user?['name']?.toString() ?? '', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        Text(user?['email']?.toString() ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _buildMenuTile(
          context,
          icon: Icons.edit_outlined,
          title: 'Chỉnh sửa hồ sơ',
          onTap: () => context.push(RouteNames.editProfile),
          isDark: isDark,
        ),
        _buildMenuTile(
          context,
          icon: Icons.lock_outline,
          title: 'Đổi mật khẩu',
          onTap: () => context.push(RouteNames.changePassword),
          isDark: isDark,
        ),
        _buildMenuTile(
          context,
          icon: Icons.notifications_outlined,
          title: 'Thông báo',
          onTap: () => context.push(RouteNames.notifications),
          isDark: isDark,
        ),
        _buildMenuTile(
          context,
          icon: Icons.article_outlined,
          title: 'Bài đăng của tôi',
          onTap: () => context.push(RouteNames.contentList),
          isDark: isDark,
        ),
        _buildMenuTile(
          context,
          icon: Icons.feedback_outlined,
          title: 'Phản hồi',
          onTap: () => context.push(RouteNames.feedback),
          isDark: isDark,
        ),
        _buildMenuTile(
          context,
          icon: Icons.flag_outlined,
          title: 'Báo cáo vi phạm',
          onTap: () => context.push(RouteNames.report),
          isDark: isDark,
        ),
        _buildMenuTile(
          context,
          icon: Icons.settings_outlined,
          title: 'Cài đặt',
          onTap: () => context.push(RouteNames.settings),
          isDark: isDark,
        ),
        const Divider(),
        _buildMenuTile(
          context,
          icon: Icons.logout,
          title: 'Đăng xuất',
          onTap: () async {
            await SfinityApp.auth.logout();
            if (context.mounted) context.go(RouteNames.login);
          },
          isDark: isDark,
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
       child: ListTile(
         leading: Icon(
           icon,
           color: isLogout
               ? Theme.of(context).colorScheme.error
               : (isDark
                   ? const Color(0xFFF2F2F2)
                   : const Color(0xFF1F2937)),
         ),
         title: Text(
           title,
           style: TextStyle(
             color: isLogout
                 ? Theme.of(context).colorScheme.error
                 : (isDark
                     ? const Color(0xFFF2F2F2)
                     : const Color(0xFF1F2937)),
           ),
         ),
         onTap: onTap,
       ),
     );
   }
}
