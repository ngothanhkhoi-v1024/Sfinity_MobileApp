import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../places/presentation/widgets/places_search_field.dart';

enum ExploreFilter { all, place, document }

class ExploreTopPanel extends StatelessWidget {
  const ExploreTopPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.searchHint,
    required this.filter,
    required this.primary,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
  });

  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final String searchHint;
  final ExploreFilter filter;
  final Color primary;
  final ValueChanged<ExploreFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: AppColors.subtitle(context), height: 1.35),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: AppColors.panel(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlacesSearchField(
                controller: searchController,
                hint: searchHint,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
              ),
              const SizedBox(height: 8),
              _FilterRow(
                filter: filter,
                primary: primary,
                onChanged: onFilterChanged,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.primary,
    required this.onChanged,
    required this.l10n,
  });

  final ExploreFilter filter;
  final Color primary;
  final ValueChanged<ExploreFilter> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final options = [
      (ExploreFilter.all, l10n.all, Icons.grid_view_rounded),
      (ExploreFilter.place, l10n.places, Icons.place_rounded),
      (ExploreFilter.document, l10n.documents, Icons.menu_book_rounded),
    ];

    return Row(
      children: [
        for (final (f, label, icon) in options) ...[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: f != ExploreFilter.document ? 6 : 0),
              child: _FilterChip(
                label: label,
                icon: icon,
                selected: filter == f,
                primary: primary,
                onTap: () => onChanged(f),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? primary : AppColors.chipBg(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.muted(context),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.muted(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
