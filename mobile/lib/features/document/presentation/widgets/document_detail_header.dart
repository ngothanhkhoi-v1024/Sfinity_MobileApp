import 'package:flutter/material.dart';

/// Premium header card hiển thị loại tệp, tiêu đề, và danh mục của tài liệu chi tiết.
class DocumentDetailHeader extends StatelessWidget {
  const DocumentDetailHeader({
    super.key,
    required this.title,
    required this.category,
    required this.fileType,
  });

  final String title;
  final String category;
  final String fileType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    final normalizedFileType = fileType.toUpperCase();
    IconData fileIcon = Icons.article_outlined;
    if (normalizedFileType == 'PDF') {
      fileIcon = Icons.picture_as_pdf;
    } else if (normalizedFileType == 'DOCX' || normalizedFileType == 'DOC') {
      fileIcon = Icons.description;
    } else if (normalizedFileType == 'LINK') {
      fileIcon = Icons.cloud_download;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.05),
            secondaryColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(fileIcon, size: 40, color: primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
