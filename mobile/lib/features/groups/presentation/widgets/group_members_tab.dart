import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import '../controllers/group_controller.dart';
import 'member_tile.dart';

class GroupMembersTab extends StatelessWidget {
  const GroupMembersTab({
    super.key,
    required this.group,
    required this.myUid,
    required this.onInviteMember,
    required this.groupCtrl,
  });

  final GroupModel group;
  final String myUid;
  final VoidCallback onInviteMember;
  final GroupController groupCtrl;

  Future<void> _removeMember(BuildContext context, GroupMemberModel member) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : cs.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Warning
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: isDark ? 0.1 : 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_remove_rounded,
                  color: isDark ? Colors.redAccent : Colors.red.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Xóa thành viên',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content description
              Text(
                'Bạn có chắc chắn muốn xóa thành viên "${member.user.name}" khỏi nhóm học tập này không?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: cs.outline),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final success = await groupCtrl.removeMember(group.id, member.user.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa thành viên "${member.user.name}" khỏi nhóm.'),
              backgroundColor: cs.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(groupCtrl.error ?? 'Không thể xóa thành viên.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
                  isGroupAdmin: isOwnerOrAdmin,
                  isOwner: group.isOwner,
                  onRemove: () => _removeMember(context, member),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
