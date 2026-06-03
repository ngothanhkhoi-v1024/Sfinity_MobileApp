import 'package:flutter/material.dart';

/// Khung card thống nhất cho lời mời / yêu cầu trong tab Cộng đồng.
class CommunityInviteCard extends StatelessWidget {
  const CommunityInviteCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }
}

/// Tiêu đề section có thể thu gọn.
class CommunitySectionHeader extends StatelessWidget {
  const CommunitySectionHeader({
    super.key,
    required this.label,
    required this.isExpanded,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  final String label;
  final bool isExpanded;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final primary = accentColor ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: primary),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
