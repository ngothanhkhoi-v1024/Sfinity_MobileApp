import 'package:flutter/material.dart';

/// Card hiển thị một item tài liệu học tập trên bảng tin.
///
/// Hiển thị icon loại tệp, mã môn học, danh mục, tiêu đề, mô tả ngắn,
/// tên tác giả và số lượt tải xuống.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = item['body']?.toString() ?? '';
    final fileType = (item['fileType']?.toString() ?? 'pdf').toLowerCase();
    final subjectCode = item['subjectCode']?.toString() ?? '';
    final downloads = item['downloadsCount'] ?? 0;
    final author = item['author'] as Map?;
    final authorName = author?['name']?.toString() ?? 'Cộng đồng';

    final (fileIcon, iconColor) = _resolveFileIcon(fileType, theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? Colors.grey.shade200
              : Colors.grey.shade800,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File type icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(fileIcon, size: 30, color: iconColor),
              ),
              const SizedBox(width: 14),
              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        if (subjectCode.isNotEmpty)
                          _Badge(
                            text: subjectCode.toUpperCase(),
                            color: theme.colorScheme.primary,
                            bgOpacity: 0.08,
                          ),
                        if (subjectCode.isNotEmpty) const SizedBox(width: 6),
                        _Badge(
                          text: (item['category'] as Map?)?['name']
                                  ?.toString() ??
                              'Tài liệu',
                          color: Colors.grey.shade700,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        if (item['status'] == 'DRAFT') ...[
                          const SizedBox(width: 6),
                          _Badge(
                            text: 'Bản nháp',
                            color: Colors.orange.shade800,
                            backgroundColor: Colors.orange.shade100,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      item['title']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Description preview
                    Text(
                      body.split('\n').first,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Metadata row
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            authorName,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.file_download_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '$downloads',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _resolveFileIcon(String fileType, ThemeData theme) {
    switch (fileType) {
      case 'pdf':
        return (Icons.picture_as_pdf, const Color(0xFFE53935));
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: bgOpacity ?? 0.08),
        borderRadius: BorderRadius.circular(6),
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
