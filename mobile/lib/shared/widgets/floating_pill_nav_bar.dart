import 'package:flutter/material.dart';

class PillNavItem {
  const PillNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Thanh điều hướng dạng viên thuốc — nền pill trượt ôm cả icon và nhãn.
class FloatingPillNavBar extends StatelessWidget {
  const FloatingPillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
    @Deprecated('Không còn dùng nút giữa. Bỏ qua.') VoidCallback? onCenterTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<PillNavItem> items;

  static const centerSlotIndex = -1;

  static const _barHeight = 76.0;
  static const _slideDuration = Duration(milliseconds: 300);
  static const _cellInsetH = 2.0;
  static const _cellInsetV = 2.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indicatorFill = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF111111);
    final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final selectedForeground = isDark ? const Color(0xFF111111) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: _barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = items.length;
            final cellWidth = constraints.maxWidth / count;
            final pillWidth = cellWidth - _cellInsetH * 2;
            final pillHeight = constraints.maxHeight - _cellInsetV * 2;
            final pillLeft = cellWidth * selectedIndex + _cellInsetH;

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                AnimatedPositioned(
                  duration: _slideDuration,
                  curve: Curves.easeOutCubic,
                  left: pillLeft,
                  top: _cellInsetV,
                  width: pillWidth,
                  height: pillHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: indicatorFill,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    count,
                    (i) => _TabButton(
                      item: items[i],
                      selected: selectedIndex == i,
                      inactiveColor: inactiveColor,
                      selectedColor: selectedForeground,
                      onTap: () => onTabSelected(i),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.inactiveColor,
    required this.selectedColor,
    required this.onTap,
  });

  final PillNavItem item;
  final bool selected;
  final Color inactiveColor;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: selectedColor.withValues(alpha: 0.08),
          highlightColor: selectedColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 21,
                  color: color,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
