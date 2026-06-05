import 'package:flutter/material.dart';
import '../../../../core/i18n/app_text.dart';
import '../../data/models/group_model.dart';
import '../controllers/group_controller.dart';
import 'member_tile.dart';

class GroupMembersTab extends StatefulWidget {
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

  @override
  State<GroupMembersTab> createState() => _GroupMembersTabState();
}

class _GroupMembersTabState extends State<GroupMembersTab> {
  bool _isPendingExpanded = true;
  bool _isApprovedExpanded = true;

  Future<void> _removeMember(BuildContext context, GroupMemberModel member) async {
    final l10n = context.l10n;
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
              Text(
                l10n.deleteMemberConfirm,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.memberRemoved,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                        l10n.cancelBtn,
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
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(
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
      final success = await widget.groupCtrl.removeMember(widget.group.id, member.user.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.memberRemoved),
              backgroundColor: cs.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.groupCtrl.error ?? l10n.cannotRemoveMember),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPendingRequestTile(BuildContext context, ColorScheme cs, bool isDark, GroupMemberModel member) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: member.user.avatar != null && member.user.avatar!.isNotEmpty
                ? NetworkImage(member.user.avatar!)
                : null,
            child: member.user.avatar == null || member.user.avatar!.isEmpty
                ? Text(
                    member.user.name.isNotEmpty ? member.user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Decline button
          OutlinedButton(
            onPressed: () async {
              final ok = await widget.groupCtrl.removeMember(widget.group.id, member.user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? l10n.decline : (widget.groupCtrl.error ?? l10n.error)),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.declineBtn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5)),
          ),
          const SizedBox(width: 6),
          // Approve button
          FilledButton(
            onPressed: () async {
              final ok = await widget.groupCtrl.approveMember(widget.group.id, member.user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? l10n.success : (widget.groupCtrl.error ?? l10n.error)),
                    backgroundColor: ok ? Colors.green.shade700 : null,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.approveBtn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final isOwnerOrAdmin = widget.group.isAdmin || widget.group.members.any((m) => m.user.id == widget.myUid && (m.role == 'OWNER' || m.role == 'ADMIN'));

    final approvedMembers = widget.group.members.where((m) => m.status != 'PENDING').toList();
    final pendingMembers = widget.group.members.where((m) => m.status == 'PENDING').toList();

    return Container(
      color: isDark ? const Color(0xFF0A0A0A) : cs.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Add member button
          if (isOwnerOrAdmin) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: ListTile(
                onTap: widget.onInviteMember,
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
                  l10n.addMembers,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  l10n.inviteToGroup,
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
            ),
          ],

          // 2. Pending approval list section
          if (isOwnerOrAdmin && pendingMembers.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _isPendingExpanded = !_isPendingExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.joinRequestsLabel} (${pendingMembers.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      _isPendingExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (_isPendingExpanded) ...[
              ...pendingMembers.map((m) => _buildPendingRequestTile(context, cs, isDark, m)),
            ],
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? Colors.white10 : cs.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Approved members list
          InkWell(
            onTap: () => setState(() => _isApprovedExpanded = !_isApprovedExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.groupMembers(approvedMembers.length),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _isApprovedExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_isApprovedExpanded) ...[
            ...approvedMembers.map(
              (member) => MemberTile(
                member: member,
                myUid: widget.myUid,
                isGroupAdmin: isOwnerOrAdmin,
                isOwner: widget.group.isOwner,
                onRemove: () => _removeMember(context, member),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
