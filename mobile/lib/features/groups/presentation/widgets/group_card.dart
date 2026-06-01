import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  final GroupModel group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? cs.surface : cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _GroupAvatar(group: group),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Công khai',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onTertiaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (group.description != null && group.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        group.description!,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} thành viên',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _RoleBadge(role: group.myRole ?? 'MEMBER', cs: cs),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group});
  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    if (group.avatarUrl != null && group.avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          group.avatarUrl!,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
        ),
      );
    }

    // Generate gradient avatar from initials
    final colors = _gradientForName(group.name);
    final initials = _initials(group.name);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'G';
  }

  List<Color> _gradientForName(String name) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFEC4899), const Color(0xFFF97316)],
      [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFFEF4444), const Color(0xFFF97316)],
      [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
    ];
    final idx = name.codeUnitAt(0) % palettes.length;
    return palettes[idx];
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.cs});
  final String role;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (role == 'OWNER') {
      return Row(
        children: [
          Icon(Icons.star, size: 12, color: Colors.amber.shade600),
          const SizedBox(width: 3),
          Text('Chủ nhóm', style: TextStyle(fontSize: 11, color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
        ],
      );
    }
    if (role == 'ADMIN') {
      return Row(
        children: [
          Icon(Icons.shield_outlined, size: 12, color: cs.primary),
          const SizedBox(width: 3),
          Text('Admin', style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
