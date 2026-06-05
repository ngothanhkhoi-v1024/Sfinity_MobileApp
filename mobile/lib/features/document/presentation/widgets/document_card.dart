import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showStatus = false,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = AppColors.primaryOf(context);
    final fileType = (item['fileType']?.toString() ?? 'pdf').toLowerCase();
    final subjectCode = item['subjectCode']?.toString() ?? '';
    final downloads = item['downloadsCount'] ?? 0;
    final author = item['author'] as Map?;
    final authorName = author?['name']?.toString() ?? l10n.community;
    final category = l10n.translateCategory(
      (item['category'] as Map?)?['name']?.toString() ?? 'Tài liệu',
    );

    final currentUserId = SfinityApp.auth.user?['id']?.toString();
    final isAuthor = item['authorId']?.toString() == currentUserId;
    final status = item['status']?.toString();
    final fileIcon = _resolveFileIcon(fileType);

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Icon(fileIcon, size: 20, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.title(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (subjectCode.isNotEmpty) subjectCode.toUpperCase(),
                        category,
                        authorName,
                        '$downloads ${l10n.download.toLowerCase()}',
                      ].where((e) => e.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                    ),
                    if (isAuthor && showStatus && status != null && status != 'PUBLISHED')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _statusLabel(l10n, status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted(context)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveFileIcon(String fileType) {
    return switch (fileType) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'docx' || 'doc' => Icons.description_outlined,
      'link' => Icons.link_rounded,
      _ => Icons.article_outlined,
    };
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'DRAFT' => l10n.statusDraft,
      'PENDING' => l10n.statusPending,
      'REJECTED' => l10n.statusRejected,
      'HIDDEN' => l10n.statusHidden,
      _ => status,
    };
  }
}
