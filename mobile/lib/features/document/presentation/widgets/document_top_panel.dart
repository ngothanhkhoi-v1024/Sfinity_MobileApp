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
        if (!embedded) ...[
          Text(
            l10n.studyMaterials,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          communityMode
              ? l10n.documentsCategory
              : l10n.yourUploadedDocuments,
          style: TextStyle(fontSize: embedded ? 13 : 14, color: AppColors.subtitle(context), height: 1.35),
        ),
        const SizedBox(height: 10),
        DocumentModeToggle(
          communityMode: communityMode,
          onChanged: onModeChanged,
          compact: true,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: AppColors.panel(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  // Nút Lọc bên phải thanh tìm kiếm
                  Material(
                    color: showFilters ? primary.withValues(alpha: 0.1) : AppColors.chipBg(context),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onToggleFilters,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.filter_list_rounded,
                          color: showFilters ? primary : AppColors.muted(context),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (showFilters) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final selected = selectedCategory == cat;
                      return _CategoryChip(
                        label: cat,
                        selected: selected,
                        primary: primary,
                        onTap: () => onCategorySelected(cat),
                      );
                    },
                  ),
                ),
              ],
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
    final isDark = AppColors.isDark(context);

    return Material(
      color: selected ? primary : AppColors.chipBg(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
            ),
          ),
        ),
      ),
    );
  }
}
