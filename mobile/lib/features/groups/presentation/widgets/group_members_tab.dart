import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import 'member_tile.dart';

class GroupMembersTab extends StatelessWidget {
  const GroupMembersTab({
    super.key,
    required this.group,
    required this.myUid,
    required this.onInviteMember,
  });

  final GroupModel group;
  final String myUid;
  final VoidCallback onInviteMember;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final isOwnerOrAdmin = group.isAdmin || group.members.any((m) => m.user.id == myUid && (m.role == 'OWNER' || m.role == 'ADMIN'));

    return Container(
      color: isDark ? const Color(0xFF0A0A0A) : cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Thành viên nhóm (${group.members.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: group.members.length + (isOwnerOrAdmin ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (isOwnerOrAdmin && i == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: ListTile(
                      onTap: onInviteMember,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: cs.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Thêm thành viên',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Mời bạn bè vào nhóm học tập này',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                final member = group.members[isOwnerOrAdmin ? i - 1 : i];
                return MemberTile(
                  member: member,
                  myUid: myUid,
                  isGroupAdmin: false,
                  isOwner: group.isOwner,
                  onRemove: null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
