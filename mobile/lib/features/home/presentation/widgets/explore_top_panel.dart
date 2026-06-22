import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../places/presentation/widgets/places_search_field.dart';

enum ExploreFilter { all, place, document }

class ExploreTopPanel extends StatelessWidget {
  const ExploreTopPanel({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    return PlacesSearchField(
      controller: searchController,
      hint: searchHint,
      onChanged: onSearchChanged,
      onSubmitted: onSearchSubmitted,
    );
  }
}

/// Bộ lọc Tất cả / Địa điểm / Tài liệu — đặt ngay trên feed Mới nhất.
class ExploreFilterRow extends StatelessWidget {
  const ExploreFilterRow({
    super.key,
    required this.filter,
    required this.primary,
    required this.onChanged,
  });

  final ExploreFilter filter;
  final Color primary;
  final ValueChanged<ExploreFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (ExploreFilter.all, l10n.all),
      (ExploreFilter.place, l10n.places),
      (ExploreFilter.document, l10n.documents),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chipBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final (f, label) in options)
              Expanded(
                child: _FilterChip(
                  label: label,
                  selected: filter == f,
                  primary: primary,
                  onTap: () => onChanged(f),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: selected
          ? (isDark ? const Color(0xFF2A2A2A) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      elevation: selected && !isDark ? 0.5 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : AppColors.muted(context),
            ),
          ),
        ),
      ),
    );
  }
}
