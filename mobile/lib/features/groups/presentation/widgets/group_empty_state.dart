import 'package:flutter/material.dart';

class GroupEmptyState extends StatelessWidget {
  const GroupEmptyState({super.key, required this.onCreateGroup});
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_outlined, size: 56, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text('Chưa có nhóm nào', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Tạo nhóm học tập hoặc chuyển sang Tab Khám phá để tham gia các nhóm học tập công khai ngay!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateGroup,
              icon: const Icon(Icons.add),
              label: const Text('Tạo nhóm mới'),
            ),
          ],
        ),
      ),
    );
  }
}
