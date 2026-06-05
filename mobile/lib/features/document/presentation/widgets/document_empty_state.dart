import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class DocumentEmptyState extends StatelessWidget {
  const DocumentEmptyState({
    super.key,
    required this.hasSearchQuery,
    this.onClearSearch,
    this.onPrimaryAction,
  });

  final bool hasSearchQuery;
  final VoidCallback? onClearSearch;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = AppColors.primaryOf(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 120),
      children: [
        Column(
          children: [
            Icon(
              hasSearchQuery ? Icons.search_off_rounded : Icons.menu_book_outlined,
              size: 40,
              color: AppColors.muted(context),
            ),
            const SizedBox(height: 14),
            Text(
              hasSearchQuery ? l10n.noSearchResults('') : l10n.noDocumentsFound,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.title(context),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearchQuery
                  ? l10n.clearSearch
                  : l10n.uploadStudyMaterialsSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted(context), height: 1.4),
            ),
            if (!hasSearchQuery && onPrimaryAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onPrimaryAction,
                icon: Icon(Icons.upload_file_outlined, size: 18, color: primary),
                label: Text(l10n.uploadDocument),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            if (hasSearchQuery && onClearSearch != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onClearSearch, child: Text(l10n.clearSearch)),
            ],
          ],
        ),
      ],
    );
  }
}
