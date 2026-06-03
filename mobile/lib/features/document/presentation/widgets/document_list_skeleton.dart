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
        Container(height: 28, width: 180, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 8),
        Container(height: 14, width: 240, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 12),
        Container(height: 44, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(14))),
        const SizedBox(height: 10),
        Container(height: 120, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 12),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 88,
              decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
