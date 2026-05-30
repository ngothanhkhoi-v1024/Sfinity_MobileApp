import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Thẻ hiển thị đánh giá & nhận xét của một sinh viên cho tài liệu
class DocumentReviewCard extends StatelessWidget {
  const DocumentReviewCard({
    super.key,
    required this.review,
    required this.isAuthor,
    required this.primaryColor,
  });

  final Map<String, dynamic> review;
  final bool isAuthor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorName = (review['author'] as Map?)?['name']?.toString() ?? 'Người dùng Sfinity';
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    final comment = review['comment']?.toString() ?? '';
    final dateVal = review['createdAt'] != null
        ? (review['createdAt'] is DateTime
            ? review['createdAt'] as DateTime
            : DateTime.tryParse(review['createdAt'].toString()) ?? DateTime.now())
        : DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(dateVal);

    return Card(
      elevation: 0,
      color: isAuthor 
          ? (theme.brightness == Brightness.light 
              ? Colors.green.shade50.withValues(alpha: 0.3) 
              : const Color(0xFF0C2E0E).withValues(alpha: 0.15))
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAuthor 
              ? Colors.green.withValues(alpha: 0.3) 
              : theme.dividerColor,
          width: isAuthor ? 1.2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: isAuthor
                ? const Border(left: BorderSide(color: Colors.green, width: 4.0))
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pinned tag for Author Review
              if (isAuthor) ...[
                Row(
                  children: [
                    const Icon(Icons.push_pin, size: 10, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Bình luận được ghim từ Tác giả',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isAuthor
                        ? Colors.green.withValues(alpha: 0.1)
                        : primaryColor.withValues(alpha: 0.1),
                    radius: 16,
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: isAuthor ? Colors.green : primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                if (isAuthor) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'Tác giả',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Row(
                              children: List.generate(5, (starIdx) {
                                return Icon(
                                  starIdx < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 13,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
