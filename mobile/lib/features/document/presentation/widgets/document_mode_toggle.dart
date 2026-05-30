import 'package:flutter/material.dart';

/// Một Segmented Control / Toggle trượt cực kỳ premium và mượt mà
/// giúp người dùng chuyển đổi giữa chế độ "Cộng đồng" và "Cá nhân".
class DocumentModeToggle extends StatelessWidget {
  const DocumentModeToggle({
    super.key,
    required this.communityMode,
    required this.onChanged,
  });

  final bool communityMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Thiết kế bảng màu premium hài hòa với theme chung
    final backgroundColor = isDark
        ? const Color(0xFF151515) // Sleek dark HSL tailored
        : const Color(0xFFF3F4F6); // Soft premium light grey
    
    final borderColor = isDark
        ? Colors.grey.shade900
        : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double tabWidth = width / 2;

            return Stack(
              children: [
                // Thanh trượt / Sliding Selector Pill
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  alignment: communityMode
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: tabWidth - 4,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Các nút nhấn chọn chế độ
                Row(
                  children: [
                    // Tab Cộng đồng
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(true),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.public_outlined,
                                size: 18,
                                color: communityMode
                                    ? Colors.white
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                              const SizedBox(width: 8),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: communityMode
                                      ? Colors.white
                                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  fontWeight: communityMode
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                                child: const Text('Cộng đồng'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Tab Cá nhân
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(false),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_pin_outlined,
                                size: 18,
                                color: !communityMode
                                    ? Colors.white
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                              const SizedBox(width: 8),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: !communityMode
                                      ? Colors.white
                                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  fontWeight: !communityMode
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                                child: const Text('Cá nhân'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
