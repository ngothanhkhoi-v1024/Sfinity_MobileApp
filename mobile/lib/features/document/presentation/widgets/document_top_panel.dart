import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../places/presentation/widgets/places_search_field.dart';
import 'document_mode_toggle.dart';

class DocumentTopPanel extends StatelessWidget {
  const DocumentTopPanel({
    super.key,
    required this.communityMode,
    required this.onModeChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.showFilters,
    required this.onToggleFilters,
    this.embedded = false,
  });

  final bool communityMode;
  final ValueChanged<bool> onModeChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final bool showFilters;
  final VoidCallback onToggleFilters;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentModeToggle(
          communityMode: communityMode,
          onChanged: onModeChanged,
          compact: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PlacesSearchField(
                controller: searchController,
                hint: l10n.searchDocumentHint,
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: showFilters
                  ? primary.withValues(alpha: 0.08)
                  : AppColors.chipBg(context),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onToggleFilters,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.tune_rounded,
                    color: showFilters ? primary : AppColors.muted(context),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeInCubic,
          sizeCurve: Curves.easeOutCubic,
          crossFadeState: showFilters
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: [
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final selected = selectedCategory == cat;
                    return _CategoryChip(
                      label: l10n.translateCategory(cat),
                      selected: selected,
                      primary: primary,
                      onTap: () => onCategorySelected(cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    return Material(
      color: selected ? primary.withValues(alpha: 0.08) : AppColors.card(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.35)
                  : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? primary : AppColors.muted(context),
            ),
          ),
        ),
      ),
    );
  }
}
