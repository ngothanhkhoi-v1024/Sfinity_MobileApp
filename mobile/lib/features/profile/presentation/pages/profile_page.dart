import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SfinityApp.auth.user;
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
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Chỉnh sửa hồ sơ'),
          onTap: () => context.push(RouteNames.editProfile),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Đổi mật khẩu'),
          onTap: () => context.push(RouteNames.changePassword),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Thông báo'),
          onTap: () => context.push(RouteNames.notifications),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: const Text('Bài đăng của tôi'),
          onTap: () => context.push(RouteNames.contentList),
        ),
        ListTile(
          leading: const Icon(Icons.feedback_outlined),
          title: const Text('Phản hồi'),
          onTap: () => context.push(RouteNames.feedback),
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Báo cáo vi phạm'),
          onTap: () => context.push(RouteNames.report),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Cài đặt'),
          onTap: () => context.push(RouteNames.settings),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: const Text('Đăng xuất'),
          onTap: () async {
            await SfinityApp.auth.logout();
            if (context.mounted) context.go(RouteNames.login);
          },
        ),
      ],
    );
  }
}
