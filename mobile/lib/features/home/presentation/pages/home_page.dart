import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Xem nội dung'),
            subtitle: const Text('Danh sách bài viết đã xuất bản'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.documentList),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Thông báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.notifications),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Gửi phản hồi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.feedback),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Báo cáo vi phạm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.report),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Cài đặt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.settings),
          ),
        ),
      ],
    );
  }
}
