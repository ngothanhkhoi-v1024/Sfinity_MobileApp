import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../friendships/presentation/widgets/user_profile_bottom_sheet.dart';
import '../../data/models/group_model.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.myUid,
    required this.isGroupAdmin,
    required this.isOwner,
    this.onRemove,
  });

  final GroupMemberModel member;
  final String myUid;
  final bool isGroupAdmin;
  final bool isOwner;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMe = member.user.id == myUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: isMe
            ? null
            : () => UserProfileBottomSheet.show(
                  context,
                  member.user,
                  SfinityApp.friendshipController,
                ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          backgroundImage: member.user.avatar != null && member.user.avatar!.isNotEmpty
              ? NetworkImage(member.user.avatar!)
              : null,
          backgroundColor: cs.primaryContainer,
          child: member.user.avatar == null || member.user.avatar!.isEmpty
              ? Text(
                  member.user.name.isNotEmpty ? member.user.name[0].toUpperCase() : '?',
                  style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(member.user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (isMe) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Bạn',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: member.user.email != null
            ? Text(member.user.email!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11))
            : null,
        trailing: member.role == 'OWNER'
            ? Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 24),
              )
            : member.role == 'ADMIN'
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.shield_rounded, color: cs.primary, size: 24),
                  )
                : (isGroupAdmin && !isMe && onRemove != null)
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onRemove,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.remove_circle_outline, color: cs.error, size: 24),
                        ),
                      )
                    : null,
      ),
    );
  }
}
