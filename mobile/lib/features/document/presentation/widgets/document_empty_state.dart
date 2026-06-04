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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.22 : 0.06,
                ),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.22),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOf(context),
                          AppColors.secondaryOf(context),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOf(context).withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      hasSearchQuery
                          ? Icons.search_off_rounded
                          : Icons.menu_book_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                hasSearchQuery ? l10n.noSearchResults('') : l10n.noDocumentsFound,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                hasSearchQuery
                    ? l10n.noSearchResults('')
                    : l10n.uploadStudyMaterialsSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (!hasSearchQuery && onPrimaryAction != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPrimaryAction,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(l10n.uploadDocument),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
              if (hasSearchQuery && onClearSearch != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.clearSearch),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryOf(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      side: BorderSide(
                        color: AppColors.primaryOf(context).withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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
