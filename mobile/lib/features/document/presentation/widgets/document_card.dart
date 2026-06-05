import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
    final theme = Theme.of(context);
    final body = item['body']?.toString().trim() ?? '';
    final fileType = (item['fileType']?.toString() ?? 'pdf').toLowerCase();
    final subjectCode = item['subjectCode']?.toString().trim() ?? '';
    final downloads = item['downloadsCount'] ?? 0;
    final author = item['author'] as Map?;
    final authorName = author?['name']?.toString() ?? l10n.community;
    final fileUrl = item['fileUrl']?.toString().trim() ?? '';
    final categoryName = l10n.translateCategory(
      (item['category'] as Map?)?['name']?.toString() ?? 'Tai lieu',
    );

    final status = item['status']?.toString();
    final description = body.isEmpty ? '' : body.split('\n').first.trim();

    final (fileIcon, accentColor) = _resolveFileIcon(fileType, theme);
    final statusBadge = _buildStatusBadge(context, status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DocumentPreviewThumbnail(
                fileType: fileType,
                fileUrl: fileUrl,
                accentColor: accentColor,
                icon: fileIcon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        height: 1.18,
                        color: AppColors.title(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (subjectCode.isNotEmpty)
                          _Badge(
                            text: subjectCode.toUpperCase(),
                            color: theme.colorScheme.primary,
                            bgOpacity: 0.10,
                          ),
                        _Badge(
                          text: categoryName,
                          color: AppColors.muted(context),
                          backgroundColor: AppColors.chipBg(context),
                        ),
                        if (statusBadge != null && showStatus)
                          statusBadge,
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.muted(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.muted(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            authorName,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.file_download_outlined,
                          size: 14,
                          color: AppColors.muted(context),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$downloads',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted(context),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Badge? _buildStatusBadge(BuildContext context, String? status) {
    final l10n = context.l10n;
    switch (status) {
      case 'DRAFT':
        return _Badge(
          text: l10n.statusDraft,
          color: Colors.orange.shade800,
          backgroundColor: Colors.orange.shade100,
        );
      case 'PENDING':
        return _Badge(
          text: l10n.statusPending,
          color: Colors.blue.shade800,
          backgroundColor: Colors.blue.shade100,
        );
      case 'REJECTED':
        return _Badge(
          text: l10n.statusRejected,
          color: Colors.red.shade800,
          backgroundColor: Colors.red.shade100,
        );
      case 'HIDDEN':
        return _Badge(
          text: l10n.statusHidden,
          color: Colors.grey.shade800,
          backgroundColor: Colors.grey.shade200,
        );
      case 'PUBLISHED':
        return _Badge(
          text: l10n.statusPublished,
          color: Colors.green.shade800,
          backgroundColor: Colors.green.shade100,
        );
      default:
        return null;
    }
  }

  (IconData, Color) _resolveFileIcon(String fileType, ThemeData theme) {
    switch (fileType) {
      case 'pdf':
        return (Icons.picture_as_pdf, AppColors.primary);
      case 'docx':
      case 'doc':
        return (Icons.description, const Color(0xFF1E88E5));
      case 'link':
        return (Icons.link, const Color(0xFF8E24AA));
      default:
        return (Icons.article_outlined, theme.colorScheme.primary);
    }
  }
}

class _DocumentPreviewThumbnail extends StatelessWidget {
  const _DocumentPreviewThumbnail({
    required this.fileType,
    required this.fileUrl,
    required this.accentColor,
    required this.icon,
  });

  final String fileType;
  final String fileUrl;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 118,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          if (fileType == 'pdf' && fileUrl.isNotEmpty)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppColors.isDark(context) ? 0.12 : 0.05,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: IgnorePointer(
                    child: SfPdfViewer.network(
                      fileUrl,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: AppColors.isDark(context) ? 0.12 : 0.05,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 18,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 12,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 14,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: index == 2 ? 0 : 6),
                    child: Container(
                      width: index == 1 ? 44 : 56,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PreviewBar(height: 38, color: accentColor.withValues(alpha: 0.72)),
                  const SizedBox(width: 6),
                  _PreviewBar(height: 28, color: accentColor.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  _PreviewBar(height: 48, color: accentColor),
                ],
              ),
            ),
          ],
          if (fileType != 'pdf')
            Positioned(
              right: 10,
              bottom: 10,
              child: Icon(
                icon,
                size: 16,
                color: accentColor.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({
    required this.height,
    required this.color,
  });

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    this.backgroundColor,
    this.bgOpacity,
  });

  final String text;
  final Color color;
  final Color? backgroundColor;
  final double? bgOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: bgOpacity ?? 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
