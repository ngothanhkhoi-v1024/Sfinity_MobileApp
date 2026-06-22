import 'package:flutter/material.dart';

import '../../../../core/constants/place_tags.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

/// Bộ lọc bản đồ địa điểm: đánh giá sao + tiện nghi (gọn, cuộn dọc khi mở rộng).
class PlaceMapFilterPanel extends StatelessWidget {
  const PlaceMapFilterPanel({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.minRating,
    required this.onMinRatingChanged,
  });

  final Set<String> selectedTags;
  final ValueChanged<Set<String>> onTagsChanged;
  final int? minRating;
  final ValueChanged<int?> onMinRatingChanged;

  static const _ratingOptions = <int?>[null, 3, 4, 5];

  bool get _hasActiveFilters => selectedTags.isNotEmpty || minRating != null;

  void _toggleTag(String id) {
    final next = Set<String>.from(selectedTags);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onTagsChanged(next);
  }

  void _clearAll() {
    onTagsChanged({});
    onMinRatingChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = AppColors.isDark(context);
    final chipSelectedColor = primary.withValues(alpha: isDark ? 0.28 : 0.14);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mapFilters,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: Text(l10n.removeFilter, style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.filterByRating,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted(context),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ratingOptions.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = _ratingOptions[index];
                final selected = minRating == value;
                final label = value == null ? l10n.filterRatingAny : l10n.filterRatingMin(value);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (value != null) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: selected ? primary : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Text(label, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: selected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  selectedColor: chipSelectedColor,
                  onSelected: (_) => onMinRatingChanged(value),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.filterAmenities,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted(context),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in PlaceTags.all)
                FilterChip(
                  label: Text(tag.label, style: const TextStyle(fontSize: 12)),
                  avatar: Icon(tag.icon, size: 15),
                  selected: selectedTags.contains(tag.id),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  selectedColor: chipSelectedColor,
                  onSelected: (_) => _toggleTag(tag.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
