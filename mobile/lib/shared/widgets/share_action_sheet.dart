import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_names.dart';

/// Bottom sheet: chia sẻ địa điểm hoặc đăng tài liệu học tập.
void showShareActionSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chia sẻ trên Sfinity',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Địa điểm học tập hoặc tài liệu cho cộng đồng',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _ShareOption(
                icon: Icons.place_outlined,
                title: 'Chia sẻ địa điểm',
                subtitle: 'Thư viện, quán cà phê, không gian học nhóm…',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.placeShare);
                },
              ),
              const SizedBox(height: 12),
              _ShareOption(
                icon: Icons.menu_book_outlined,
                title: 'Đăng tài liệu học tập',
                subtitle: 'Ghi chú, slide, đề thi, tóm tắt môn học…',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    RouteNames.contentCreate,
                    extra: const {'contentType': 'document'},
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
