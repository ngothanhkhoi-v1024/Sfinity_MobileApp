import 'package:flutter/material.dart';

/// Thanh lọc + chuyển chế độ xem cho tab Địa điểm.
class PlacesHeaderPanel extends StatelessWidget {
  const PlacesHeaderPanel({
    super.key,
    required this.communityMode,
    required this.listView,
    required this.onCommunityChanged,
    required this.onViewChanged,
  });

  final bool communityMode;
  final bool listView;
  final ValueChanged<bool> onCommunityChanged;
  final ValueChanged<bool> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF242424) : Colors.white;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, listView ? 4 : 8, 16, listView ? 0 : 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(20),
            bottom: listView ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE8EAED),
          ),
          boxShadow: listView
              ? null
              : [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScopeToggle(
              communityMode: communityMode,
              onChanged: onCommunityChanged,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _ViewToggle(
              listView: listView,
              onChanged: onViewChanged,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({
    required this.communityMode,
    required this.onChanged,
    required this.isDark,
  });

  final bool communityMode;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final track = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScopeChip(
              label: 'Cộng đồng',
              icon: Icons.groups_outlined,
              selected: communityMode,
              primary: primary,
              isDark: isDark,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ScopeChip(
              label: 'Của tôi',
              icon: Icons.person_outline,
              selected: !communityMode,
              primary: primary,
              isDark: isDark,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? primary.withValues(alpha: 0.22) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: selected && !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  color: selected
                      ? (isDark ? Colors.white : const Color(0xFF1F2937))
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.listView,
    required this.onChanged,
    required this.isDark,
  });

  final bool listView;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: _ViewChip(
            label: 'Bản đồ',
            icon: Icons.map_outlined,
            selected: !listView,
            primary: primary,
            isDark: isDark,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ViewChip(
            label: 'Danh sách',
            icon: Icons.format_list_bulleted_rounded,
            selected: listView,
            primary: primary,
            isDark: isDark,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.35)
                : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
