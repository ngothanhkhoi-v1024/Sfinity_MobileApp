import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';

class PlacesHeaderPanel extends StatelessWidget {
  const PlacesHeaderPanel({
    super.key,
    required this.communityMode,
    required this.listView,
    required this.onCommunityChanged,
    required this.onViewChanged,
    this.embedded = false,
  });

  final bool communityMode;
  final bool listView;
  final ValueChanged<bool> onCommunityChanged;
  final ValueChanged<bool> onViewChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final content = Row(
      children: [
        Expanded(
          flex: 3,
          child: _SegmentedTrack(
            isDark: isDark,
            children: [
              _SegmentTab(
                label: l10n.communityContent,
                icon: Icons.groups_rounded,
                selected: communityMode,
                primary: primary,
                isDark: isDark,
                onTap: () => onCommunityChanged(true),
              ),
              _SegmentTab(
                label: l10n.personal,
                icon: Icons.bookmark_rounded,
                selected: !communityMode,
                primary: primary,
                isDark: isDark,
                onTap: () => onCommunityChanged(false),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _SegmentedTrack(
            isDark: isDark,
            children: [
              _SegmentTab(
                label: l10n.map,
                icon: Icons.map_rounded,
                selected: !listView,
                primary: primary,
                isDark: isDark,
                onTap: () => onViewChanged(false),
                compact: true,
              ),
              _SegmentTab(
                label: l10n.list,
                icon: Icons.view_list_rounded,
                selected: listView,
                primary: primary,
                isDark: isDark,
                onTap: () => onViewChanged(true),
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: content,
      );
    }

    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, listView ? 4 : 8, 16, listView ? 0 : 0),
        padding: const EdgeInsets.all(10),
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
        child: content,
      ),
    );
  }
}

class _SegmentedTrack extends StatelessWidget {
  const _SegmentedTrack({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: children),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? primary.withValues(alpha: 0.25) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Tooltip(
              message: label,
              child: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 8 : 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: compact ? 16 : 17,
                    color: selected
                        ? primary
                        : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? (isDark ? Colors.white : const Color(0xFF1F2937))
                              : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
