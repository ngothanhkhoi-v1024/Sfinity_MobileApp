import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../places/presentation/widgets/places_search_field.dart';
import 'document_mode_toggle.dart';

/// Khối điều khiển gọn: chế độ + tìm kiếm + lọc danh mục.
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
    this.resultCount,
    this.embedded = false,
  });

  final bool communityMode;
  final ValueChanged<bool> onModeChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final int? resultCount;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embedded) ...[
          Text(
            'Tài liệu học tập',
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
              ? 'Bài giảng, đề thi và ghi chú từ cộng đồng'
              : 'Tài liệu bạn đã đăng tải',
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
              PlacesSearchField(
                controller: searchController,
                hint: 'Tìm tài liệu, mã môn, từ khóa…',
                onChanged: onSearchChanged,
              ),
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
          ),
        ),
        if (resultCount != null) ...[
          const SizedBox(height: 10),
          _DocumentCountStrip(count: resultCount!, communityMode: communityMode),
        ],
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

class _DocumentCountStrip extends StatelessWidget {
  const _DocumentCountStrip({
    required this.count,
    required this.communityMode,
  });

  final int count;
  final bool communityMode;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryTint(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            communityMode ? Icons.public_rounded : Icons.person_rounded,
            size: 18,
            color: primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$count tài liệu',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
          ),
          const Spacer(),
          Icon(Icons.menu_book_rounded, size: 16, color: primary.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
