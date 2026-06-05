import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DocumentListSkeleton extends StatelessWidget {
  const DocumentListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final skeleton = AppColors.chipBg(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Container(height: 40, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 10),
        Container(height: 48, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 12),
        ...List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 64,
              decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
