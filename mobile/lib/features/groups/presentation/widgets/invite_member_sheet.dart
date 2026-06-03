import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import '../../../friendships/data/models/friend_model.dart';
import '../controllers/group_controller.dart';
import '../../../friendships/presentation/controllers/friendship_controller.dart';
import '../../../../core/i18n/app_text.dart';

class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({
    super.key,
    required this.group,
    required this.groupCtrl,
    required this.friendCtrl,
  });

  final GroupModel group;
  final GroupController groupCtrl;
  final FriendshipController friendCtrl;

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Map<String, bool> _sendingMap = {};

  void _onFriendCtrlChange() {
    if (mounted) setState(() {});
  }

  void _onGroupCtrlChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.groupCtrl.loadGroupInvitations(widget.group.id);
    widget.friendCtrl.loadFriends();
    widget.friendCtrl.addListener(_onFriendCtrlChange);
    widget.groupCtrl.addListener(_onGroupCtrlChange);
  }

  @override
  void dispose() {
    widget.friendCtrl.removeListener(_onFriendCtrlChange);
    widget.groupCtrl.removeListener(_onGroupCtrlChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // Xác định tập hợp các ID thành viên hiện tại để loại trừ/gắn nhãn
    final existingMemberIds = widget.group.members.map((m) => m.user.id).toSet();

    // Xác định tập hợp các ID có lời mời đang chờ (PENDING)
    final pendingInvitedIds = widget.groupCtrl.groupInvitations
        .where((inv) => inv['status'] == 'PENDING')
        .map((inv) => inv['inviteeId']?.toString() ?? '')
        .toSet();

    List<FriendUser> displayUsers = [];
    final isSearchingMode = _query.trim().length >= 2;

    if (isSearchingMode) {
      displayUsers = widget.friendCtrl.searchResults;
    } else {
      // Ô tìm kiếm trống -> hiển thị danh sách bạn bè gợi ý
      displayUsers = widget.friendCtrl.friends.map((f) => f.user).toList();
    }

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : cs.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.addMembers,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : cs.onSurface,
                ),
              ),
              if (widget.friendCtrl.isSearching)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: l10n.searchByNameEmail,
              hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.35) : cs.onSurfaceVariant.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white.withValues(alpha: 0.4) : cs.onSurfaceVariant.withValues(alpha: 0.6)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                        widget.friendCtrl.clearSearch();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : cs.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            onChanged: (val) {
              setState(() => _query = val);
              widget.friendCtrl.searchUsers(val);
            },
          ),
          const SizedBox(height: 16),
          Text(
            isSearchingMode ? l10n.searchResults : l10n.suggestedFriends,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.45) : cs.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.friendCtrl.isSearching && displayUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : displayUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 48,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isSearchingMode ? l10n.noUsersFound : l10n.noFriendsList,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayUsers.length,
                        itemBuilder: (ctx, i) {
                          final user = displayUsers[i];
                          final isMember = existingMemberIds.contains(user.id);
                          final hasPendingInvite = pendingInvitedIds.contains(user.id);
                          final isSending = _sendingMap[user.id] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.02) : cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.03) : cs.outlineVariant.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                backgroundColor: cs.primaryContainer,
                                child: user.avatar == null || user.avatar!.isEmpty
                                    ? Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: user.email != null
                                  ? Text(
                                      user.email!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : cs.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              trailing: Builder(
                                builder: (context) {
                                  if (isMember) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        l10n.member,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                                        ),
                                      ),
                                    );
                                  }

                                  if (isSending) {
                                    return const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  }

                                  if (hasPendingInvite) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        l10n.pending,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    );
                                  }

                                  // Nút Mời chưa gửi
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [cs.primary, const Color(0xFFFF5A36)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        setState(() => _sendingMap[user.id] = true);
                                        final ok = await widget.groupCtrl.inviteMember(widget.group.id, user.id);
                                        setState(() => _sendingMap[user.id] = false);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(ok
                                                  ? l10n.sendInviteSuccess(user.name)
                                                  : (widget.groupCtrl.error ?? l10n.sendInviteFailed)),
                                              backgroundColor: ok ? Colors.green.shade700 : cs.error,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(l10n.invite, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
