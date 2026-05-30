import 'package:flutter/material.dart';

/// Một widget tile hiển thị thông tin metadata chi tiết của tài liệu (mã môn học, định dạng, dung lượng, lượt tải).
class DocumentInfoTile extends StatelessWidget {
  const DocumentInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Màu nền mềm mại và có độ tương phản chuẩn xác cho Light/Dark Mode
    final backgroundColor = isDark
        ? const Color(0xFF161616) // HSL tailored dark card
        : const Color(0xFFF9FAFB); // Soft premium light grey (slimmer contrast)

    final effectiveAccentColor = accentColor ?? theme.colorScheme.primary;
    final iconBgColor = effectiveAccentColor.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Khung chứa Icon bo tròn tinh xảo (nhỏ hơn và dùng accentColor riêng biệt)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              size: 14, 
              color: effectiveAccentColor,
            ),
          ),
          const SizedBox(width: 8),
          
          // Nội dung text chi tiết (thu gọn size chữ cho nhỏ gọn sắc sảo)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

