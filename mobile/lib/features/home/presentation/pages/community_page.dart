import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../friendships/presentation/controllers/friendship_controller.dart';
import '../../../friendships/presentation/widgets/friends_list_tab.dart';
import '../../../groups/presentation/controllers/group_controller.dart';
import '../../../groups/presentation/widgets/discover_group_card.dart';
import '../../../groups/presentation/widgets/group_card.dart';
import '../../../groups/presentation/widgets/group_empty_state.dart';
import '../../../groups/presentation/widgets/group_error_state.dart';
import '../../../places/presentation/widgets/places_search_field.dart';
import '../widgets/community_invite_card.dart';
import '../widgets/community_segmented_tabs.dart';

/// Tab "Cộng đồng" tổng hợp: Nhóm học tập | Bạn bè | Lời mời | Khám phá nhóm.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final GroupController _groupCtrl;
  late final FriendshipController _friendCtrl;
  String _discoverSearch = '';
  late final TextEditingController _discoverSearchCtrl;
  bool _isFriendRequestsExpanded = true;
  bool _isSentRequestsExpanded = true;
  bool _isGroupInvitesExpanded = true;

  static const int _kTabGroups = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _discoverSearchCtrl = TextEditingController();
    _discoverSearchCtrl.addListener(() {
      setState(() => _discoverSearch = _discoverSearchCtrl.text.trim());
    });

    _groupCtrl = SfinityApp.groupController;
    _friendCtrl = SfinityApp.friendshipController;

    // Load all required data
    _groupCtrl.loadMyGroups();
    _groupCtrl.loadDiscoverGroups();
    _groupCtrl.loadReceivedInvitations();
    _friendCtrl.loadFriends();
    _friendCtrl.loadPendingRequests();
    _friendCtrl.loadSentRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _discoverSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([_groupCtrl, _friendCtrl]),
      builder: (context, _) {
        final inviteCount = _groupCtrl.receivedInvitations.length;
        final pendingFriendCount = _friendCtrl.pendingRequests.length;
        final totalBadge = inviteCount + pendingFriendCount;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Cộng đồng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
            actions: [
              if (_tabController.index == _kTabGroups)
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded, size: 22),
                  tooltip: 'Tạo nhóm',
                  onPressed: () => context.push(RouteNames.groupCreate),
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: CommunitySegmentedTabs(
                controller: _tabController,
                onTap: (i) => _tabController.animateTo(i),
                tabs: [
                  const CommunityTabItem(
                    label: 'Nhóm',
                    icon: Icons.groups_rounded,
                  ),
                  const CommunityTabItem(
                    label: 'Bạn bè',
                    icon: Icons.people_rounded,
                  ),
                  CommunityTabItem(
                    label: 'Lời mời',
                    icon: Icons.mail_rounded,
                    badgeCount: totalBadge,
                  ),
                  const CommunityTabItem(
                    label: 'Khám phá',
                    icon: Icons.explore_rounded,
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMyGroupsTab(context, cs, isDark),
              FriendsListTab(controller: _friendCtrl),
              _buildInvitationsTab(context, cs, isDark),
              _buildDiscoverGroupsTab(context, cs),
            ],
          ),
        );
      },
    );
  }

  // ─── Tab 0: My Groups ────────────────────────────────────────────────────

  Widget _buildMyGroupsTab(BuildContext context, ColorScheme cs, bool isDark) {
    if (_groupCtrl.isLoading && _groupCtrl.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_groupCtrl.error != null && _groupCtrl.groups.isEmpty) {
      return GroupErrorState(
        message: _groupCtrl.error!,
        onRetry: () {
          _groupCtrl.loadMyGroups();
        },
      );
    }

    final myGroups = _groupCtrl.groups;
    if (myGroups.isEmpty) {
      return GroupEmptyState(
        onCreateGroup: () => context.push(RouteNames.groupCreate),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _groupCtrl.loadMyGroups,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: myGroups.length,
        itemBuilder: (_, i) => GroupCard(
          group: myGroups[i],
          onTap: () => context.push(
            RouteNames.groupDetail.replaceFirst(':id', myGroups[i].id),
          ),
        ),
      ),
    );
  }

  // ─── Tab 2: Invitations ─────────────────────────────────────────────────

  Widget _buildInvitationsTab(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
  ) {
    final groupInvites = _groupCtrl.receivedInvitations;
    final friendRequests = _friendCtrl.pendingRequests;
    final sentRequests = _friendCtrl.sentRequests;

    final hasGroupInvites = groupInvites.isNotEmpty;
    final hasFriendRequests = friendRequests.isNotEmpty;
    final hasSent = sentRequests.isNotEmpty;

    if (!hasGroupInvites && !hasFriendRequests && !hasSent) {
      return RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _groupCtrl.loadReceivedInvitations(),
            _friendCtrl.loadPendingRequests(),
            _friendCtrl.loadSentRequests(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(32, 64, 32, 100),
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 36,
                color: cs.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có lời mời nào',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Các lời mời kết bạn và lời mời tham gia nhóm sẽ hiện ở đây.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _groupCtrl.loadReceivedInvitations(),
          _friendCtrl.loadPendingRequests(),
          _friendCtrl.loadSentRequests(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
        children: [
          // ── Friend Requests ─────────────────────────────────────────────
          if (hasFriendRequests) ...[
            CommunitySectionHeader(
              icon: Icons.person_add_alt_rounded,
              label: 'Lời mời kết bạn (${friendRequests.length})',
              isExpanded: _isFriendRequestsExpanded,
              onTap: () => setState(
                () => _isFriendRequestsExpanded = !_isFriendRequestsExpanded,
              ),
            ),
            if (_isFriendRequestsExpanded)
              ..._buildFriendRequestCards(context, cs, isDark, friendRequests),
            const SizedBox(height: 8),
          ],

          if (hasFriendRequests && hasSent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(
                height: 1,
                color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
              ),
            ),

          // ── Sent Friend Requests ─────────────────────────────────────────
          if (hasSent) ...[
            CommunitySectionHeader(
              icon: Icons.schedule_send_rounded,
              label: 'Đã gửi (${sentRequests.length})',
              isExpanded: _isSentRequestsExpanded,
              onTap: () => setState(
                () => _isSentRequestsExpanded = !_isSentRequestsExpanded,
              ),
            ),
            if (_isSentRequestsExpanded)
              ..._buildSentRequestCards(context, cs, isDark, sentRequests),
            const SizedBox(height: 8),
          ],

          if ((hasFriendRequests || hasSent) && hasGroupInvites)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(
                height: 1,
                color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
              ),
            ),

          // ── Group Invitations ────────────────────────────────────────────
          if (hasGroupInvites) ...[
            CommunitySectionHeader(
              icon: Icons.group_add_rounded,
              label: 'Lời mời nhóm (${groupInvites.length})',
              isExpanded: _isGroupInvitesExpanded,
              onTap: () => setState(
                () => _isGroupInvitesExpanded = !_isGroupInvitesExpanded,
              ),
            ),
            if (_isGroupInvitesExpanded)
              ..._buildGroupInviteCards(context, cs, isDark, groupInvites),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFriendRequestCards(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    List<dynamic> requests,
  ) {
    return requests.map((req) {
      final user = req.requester;
      return CommunityInviteCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                    ? NetworkImage(user.avatar!)
                    : null,
                backgroundColor: cs.primaryContainer,
                child: user.avatar == null || user.avatar!.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Reject button
              OutlinedButton(
                onPressed: () async {
                  await _friendCtrl.respondRequest(req.id, false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : cs.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Từ chối',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),
              // Accept button
              FilledButton(
                onPressed: () async {
                  final ok = await _friendCtrl.respondRequest(req.id, true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Đã chấp nhận lời mời kết bạn!'
                              : (_friendCtrl.error ?? 'Đã xảy ra lỗi'),
                        ),
                        backgroundColor: ok ? Colors.green.shade700 : null,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Chấp nhận',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSentRequestCards(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    List<dynamic> requests,
  ) {
    return requests.map((req) {
      final user = req.addressee;
      return CommunityInviteCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                    ? NetworkImage(user.avatar!)
                    : null,
                backgroundColor: cs.primaryContainer,
                child: user.avatar == null || user.avatar!.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đang chờ xác nhận...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _friendCtrl.unfriend(req.id);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Đã thu hồi lời mời kết bạn.'),
                    ),
                  );
                },
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Hủy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildGroupInviteCards(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    List<dynamic> invites,
  ) {
    return invites.map((inv) {
      final inviteId = inv['id']?.toString() ?? '';
      final groupName = inv['groupName']?.toString() ?? 'Nhóm học tập';
      final inviterName = inv['inviterName']?.toString() ?? 'Ai đó';
      final avatarUrl = inv['groupAvatarUrl']?.toString();

      return CommunityInviteCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          groupName.isNotEmpty
                              ? groupName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.black87,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: inviterName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' mời bạn tham gia nhóm '),
                        TextSpan(
                          text: '"$groupName"',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final ok = await _groupCtrl.respondToInvitation(
                      inviteId,
                      false,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Đã từ chối lời mời vào nhóm "$groupName"'
                                : 'Từ chối lời mời thất bại. Vui lòng thử lại.',
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : cs.outlineVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
                      final ok = await _groupCtrl.respondToInvitation(
                        inviteId,
                        true,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Chúc mừng! Bạn đã gia nhập nhóm "$groupName"'
                                  : 'Gia nhập nhóm thất bại. Vui lòng thử lại.',
                            ),
                            backgroundColor: ok ? Colors.green.shade700 : null,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Chấp nhận',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      );
    }).toList();
  }

  // ─── Tab 3: Discover Groups ──────────────────────────────────────────────

  Widget _buildDiscoverGroupsTab(BuildContext context, ColorScheme cs) {
    final filteredGroups = _groupCtrl.discoverGroups.where((g) {
      if (_discoverSearch.isEmpty) return true;
      return g.name.toLowerCase().contains(_discoverSearch.toLowerCase()) ||
          (g.description ?? '').toLowerCase().contains(
            _discoverSearch.toLowerCase(),
          );
    }).toList();

    return RefreshIndicator(
      onRefresh: _groupCtrl.loadDiscoverGroups,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: PlacesSearchField(
              controller: _discoverSearchCtrl,
              hint: 'Tìm nhóm học tập công khai...',
              onChanged: (_) {},
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_groupCtrl.isDiscoverLoading && filteredGroups.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_groupCtrl.error != null && filteredGroups.isEmpty) {
                  return GroupErrorState(
                    message: _groupCtrl.error!,
                    onRetry: _groupCtrl.loadDiscoverGroups,
                  );
                }
                if (filteredGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: cs.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _discoverSearch.isEmpty
                              ? 'Không có nhóm mới để khám phá'
                              : 'Không tìm thấy nhóm phù hợp',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                  itemCount: filteredGroups.length,
                  itemBuilder: (_, i) {
                    final group = filteredGroups[i];
                    return DiscoverGroupCard(
                      group: group,
                      onJoin: () async {
                        final success = await _groupCtrl.joinGroup(group.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? (group.autoApprove
                                          ? 'Đã gia nhập "${group.name}" thành công!'
                                          : 'Yêu cầu gia nhập "${group.name}" đã được gửi và đang chờ duyệt!')
                                    : (_groupCtrl.error ?? 'Đã có lỗi xảy ra'),
                              ),
                              backgroundColor: success
                                  ? Colors.green.shade700
                                  : cs.error,
                            ),
                          );
                        }
                      },
                      onCancel: () async {
                        final success = await _groupCtrl.leaveGroup(group.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Đã hủy yêu cầu tham gia "${group.name}"!'
                                    : (_groupCtrl.error ?? 'Đã có lỗi xảy ra'),
                              ),
                              backgroundColor: success
                                  ? Colors.blue.shade700
                                  : cs.error,
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Create Group Dialog ─────────────────────────────────────────────────
}
