import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bar_add_button.dart';
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
  String _groupSearch = '';
  String _discoverSearch = '';
  late final TextEditingController _groupSearchCtrl;
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
    _groupSearchCtrl = TextEditingController();
    _groupSearchCtrl.addListener(() {
      setState(() => _groupSearch = _groupSearchCtrl.text.trim());
    });
    _discoverSearchCtrl = TextEditingController();
    _discoverSearchCtrl.addListener(() {
      setState(() => _discoverSearch = _discoverSearchCtrl.text.trim());
    });

    _groupCtrl = SfinityApp.groupController;
    _friendCtrl = SfinityApp.friendshipController;

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
    _groupSearchCtrl.dispose();
    _discoverSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            title: Text(l10n.community),
            actions: [
              if (_tabController.index == _kTabGroups)
                _buildCreateGroupButton(context, cs),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: CommunitySegmentedTabs(
                controller: _tabController,
                onTap: (i) => _tabController.animateTo(i),
                tabs: [
                  CommunityTabItem(
                    label: l10n.studyGroups,
                    icon: Icons.groups_rounded,
                  ),
                  CommunityTabItem(
                    label: l10n.friendsTab,
                    icon: Icons.people_rounded,
                  ),
                  CommunityTabItem(
                    label: l10n.invitesTab,
                    icon: Icons.mail_rounded,
                    badgeCount: totalBadge,
                  ),
                  CommunityTabItem(
                    label: l10n.discoverTab,
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

  Widget _buildMyGroupsTab(BuildContext context, ColorScheme cs, bool isDark) {
    final l10n = context.l10n;

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

    final query = _groupSearch.toLowerCase();
    final filteredGroups = query.isEmpty
        ? myGroups
        : myGroups.where((group) {
            return group.name.toLowerCase().contains(query) ||
                (group.description ?? '').toLowerCase().contains(query);
          }).toList();

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _groupCtrl.loadMyGroups,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: PlacesSearchField(
              controller: _groupSearchCtrl,
              hint: l10n.searchGroupHint,
              onChanged: (_) {},
            ),
          ),
          if (filteredGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 46,
                    color: cs.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noGroupsFound,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ...filteredGroups.map(
              (group) => GroupCard(
                group: group,
                onTap: () => context.push(
                  RouteNames.groupDetail.replaceFirst(':id', group.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateGroupButton(BuildContext context, ColorScheme cs) {
    return AppBarAddButton(
      tooltip: context.l10n.createGroup,
      onPressed: () => context.push(RouteNames.groupCreate),
    );
  }

  Widget _buildInvitationsTab(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
  ) {
    final l10n = context.l10n;
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
            Icon(Icons.mail_outline_rounded, size: 40, color: AppColors.muted(context)),
            const SizedBox(height: 14),
            Text(
              l10n.noInvites,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.title(context),
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
          if (hasFriendRequests) ...[
            CommunitySectionHeader(
              label: l10n.friendRequests,
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

          if (hasSent) ...[
            CommunitySectionHeader(
              label: l10n.sentRequests(sentRequests.length),
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

          if (hasGroupInvites) ...[
            CommunitySectionHeader(
              label: l10n.invitesTab,
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
    final l10n = context.l10n;
    return requests.map((req) {
      final user = req.requester;
      return CommunityInviteCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                    ? NetworkImage(user.avatar!)
                    : null,
                backgroundColor: AppColors.primaryOf(context).withValues(alpha: 0.08),
                child: user.avatar == null || user.avatar!.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primaryOf(context),
                          fontWeight: FontWeight.w700,
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
                child: Text(
                  l10n.decline,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () async {
                  final ok = await _friendCtrl.respondRequest(req.id, true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? l10n.acceptInvite
                              : (_friendCtrl.error ?? l10n.errorOccurred),
                        ),
                        backgroundColor: ok ? Colors.green.shade700 : null,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryOf(context),
                  side: BorderSide(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.accept,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
    final l10n = context.l10n;
    return requests.map((req) {
      final user = req.addressee;
      return CommunityInviteCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                    ? NetworkImage(user.avatar!)
                    : null,
                backgroundColor: AppColors.primaryOf(context).withValues(alpha: 0.08),
                child: user.avatar == null || user.avatar!.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primaryOf(context),
                          fontWeight: FontWeight.w700,
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
                      l10n.friendRequests,
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
                    SnackBar(
                      content: Text(l10n.friendRequests),
                    ),
                  );
                },
                icon: const Icon(Icons.close, size: 14),
                label: Text(l10n.cancelBtn2),
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
    final l10n = context.l10n;
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
                        TextSpan(text: ' ${l10n.invitesTab} '),
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
                                ? l10n.declineInvite
                                : l10n.errorOccurred,
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
                  child: Text(
                    l10n.decline,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final ok = await _groupCtrl.respondToInvitation(
                      inviteId,
                      true,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok ? l10n.acceptInvite : l10n.errorOccurred,
                          ),
                          backgroundColor: ok ? Colors.green.shade700 : null,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOf(context),
                    side: BorderSide(
                      color: AppColors.primaryOf(context).withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.accept,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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

  Widget _buildDiscoverGroupsTab(BuildContext context, ColorScheme cs) {
    final l10n = context.l10n;
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: PlacesSearchField(
              controller: _discoverSearchCtrl,
              hint: l10n.searchGroupHint,
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
                              ? l10n.noGroupsExplore
                              : l10n.noGroupsFound,
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
                                        ? l10n.joinGroupSuccess(group.name)
                                        : l10n.joinGroupPending(group.name))
                                    : (_groupCtrl.error ?? l10n.errorOccurred),
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
                                    ? l10n.cancelRequestSuccess(group.name)
                                    : (_groupCtrl.error ?? l10n.errorOccurred),
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
}
