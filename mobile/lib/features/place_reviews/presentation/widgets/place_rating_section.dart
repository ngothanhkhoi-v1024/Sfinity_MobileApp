import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
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

  void _openRatingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: _RatingForm(
          controller: controller,
          placeId: placeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avg = summary.avgRating;
    final count = summary.reviewCount;
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;
    final cardBg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB);
    final preview = summary.reviews.isNotEmpty ? summary.reviews.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
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
              Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                avg != null
                    ? l10n.ratingStarsCount(avg, count)
                    : l10n.noRating,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (preview != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Text(
                    _initial(preview.authorName),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    preview.comment ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.submitting
                  ? null
                  : () => _openRatingSheet(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: primary,
                side: BorderSide(color: primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.yourRating,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initial(String? name) {
  if (name == null || name.isEmpty) return '?';
  return name[0].toUpperCase();
}

class _RatingForm extends StatelessWidget {
  const _RatingForm({
    required this.controller,
    required this.placeId,
  });

  final PlaceEngagementController controller;
  final String placeId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.yourRating,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                size: 32,
              ),
            );
          }),
        ),
        TextField(
          controller: controller.commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.ratingHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: controller.submitting
              ? null
              : () async {
                  await controller.submitReview(placeId);
                  if (context.mounted) Navigator.pop(context);
                },
          child: controller.submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.sendRating),
        ),
      ],
    );
  }
}
