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

/// Thanh điều hướng dạng viên thuốc, nút [+] ở giữa (không phải tab).
class FloatingPillNavBar extends StatelessWidget {
  const FloatingPillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onCenterTap,
    required this.items,
  });

  /// Chỉ số tab: 0, 1, 3, 4 (bỏ qua 2 = nút giữa).
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterTap;
  final List<PillNavItem> items;

  static const centerSlotIndex = 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _TabButton(
              item: items[0],
              selected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            _TabButton(
              item: items[1],
              selected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            Expanded(
              child: Center(
                child: _CenterActionButton(onTap: onCenterTap),
              ),
            ),
            _TabButton(
              item: items[2],
              selected: selectedIndex == 3,
              onTap: () => onTabSelected(3),
            ),
            _TabButton(
              item: items[3],
              selected: selectedIndex == 4,
              onTap: () => onTabSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? const Color(0xFFF2F2F2) : Colors.black)
        : (isDark ? Colors.grey.shade500 : Colors.grey.shade500);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? item.selectedIcon : item.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Material(
        color: Colors.black,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
