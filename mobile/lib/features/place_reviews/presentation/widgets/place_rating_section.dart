import 'package:flutter/material.dart';

import '../../data/models/place_review_model.dart';
import '../controllers/place_engagement_controller.dart';

class PlaceRatingSection extends StatelessWidget {
  const PlaceRatingSection({
    super.key,
    required this.controller,
    required this.placeId,
    required this.summary,
  });

  final PlaceEngagementController controller;
  final String placeId;
  final PlaceReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avg = summary.avgRating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8EAED),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 28),
              const SizedBox(width: 8),
              Text(
                avg != null ? avg.toStringAsFixed(1) : '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${summary.reviewCount} đánh giá)',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Đánh giá của bạn',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: controller.submitting
                    ? null
                    : () => controller.setDraftRating(star),
                icon: Icon(
                  star <= controller.draftRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber.shade700,
                ),
              );
            }),
          ),
          TextField(
            controller: controller.commentController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Nhận xét (tuỳ chọn)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.submitting
                  ? null
                  : () => controller.submitReview(placeId),
              child: controller.submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi đánh giá'),
            ),
          ),
          if (summary.reviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Đánh giá gần đây',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...summary.reviews.take(5).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating ? Icons.star_rounded : Icons.star_outline,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.authorName ?? 'Người dùng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (r.comment != null && r.comment!.isNotEmpty)
                                Text(r.comment!, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
