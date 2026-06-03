import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Premium empty state hiển thị khi không có tài liệu hoặc không tìm thấy kết quả.
class DocumentEmptyState extends StatelessWidget {
  const DocumentEmptyState({
    super.key,
    required this.hasSearchQuery,
    this.onClearSearch,
  });

  /// Nếu true: hiển thị thông báo "Không tìm thấy kết quả" và nút xóa bộ lọc.
  final bool hasSearchQuery;

  /// Callback xóa bộ lọc tìm kiếm.
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: AppColors.panel(context, radius: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Layered circular background icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasSearchQuery
                          ? Icons.search_off_rounded
                          : Icons.menu_book_rounded,
                      size: 32,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                hasSearchQuery
                    ? 'Không tìm thấy kết quả'
                    : 'Chưa có tài liệu nào',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasSearchQuery
                    ? 'Không tìm thấy tài liệu phù hợp với từ khóa của bạn. Thử tìm mã môn học hoặc từ khóa khác xem sao!'
                    : 'Hãy là người đầu tiên chia sẻ tài liệu ôn thi hữu ích cho cộng đồng Sfinity ngay hôm nay!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasSearchQuery && onClearSearch != null) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Xóa bộ lọc tìm kiếm'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryOf(context),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
