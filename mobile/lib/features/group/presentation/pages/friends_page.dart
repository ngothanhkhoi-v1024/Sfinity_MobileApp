import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../data/models/friend_model.dart';
import '../controllers/friendship_controller.dart';
import '../widgets/friend_tile.dart';
import '../widgets/friend_request_tile.dart';
import '../widgets/user_profile_bottom_sheet.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final FriendshipController _ctrl;
  final _localSearchCtrl = TextEditingController();
  final _globalSearchCtrl = TextEditingController();
  final Set<String> _loadingRequests = {};
  String _localFilter = '';

  @override
  void initState() {
    super.initState();
    _ctrl = SfinityApp.friendshipController;
    _ctrl.loadFriends();
    _ctrl.loadPendingRequests();
    _ctrl.loadSentRequests();
    
    _localSearchCtrl.addListener(() {
      setState(() {
        _localFilter = _localSearchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _localSearchCtrl.dispose();
    _globalSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (context, _) {
                final pendingCount = _ctrl.pendingRequests.length;
                return TabBar(
                  indicatorWeight: 3.5,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorColor: cs.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Danh sách', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_alt_outlined, size: 18),
                          const SizedBox(width: 8),
                          const Text('Thêm bạn', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) {
            return TabBarView(
              children: [
                _buildFriendsTab(theme, cs),
                _buildAddFriendsTab(theme, cs),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFriendsTab(ThemeData theme, ColorScheme cs) {
    if (_ctrl.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final friends = _ctrl.friends;
    final filteredFriends = friends.where((f) {
      if (_localFilter.isEmpty) return true;
      final name = f.user.name.toLowerCase();
      final email = f.user.email?.toLowerCase() ?? '';
      return name.contains(_localFilter) || email.contains(_localFilter);
    }).toList();

    if (friends.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Chưa có bạn bè',
        subtitle: 'Chuyển qua tab "Thêm bạn" để tìm kiếm và kết nối nhé!',
      );
    }

    return Column(
      children: [
        // Local Filter Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SearchBar(
            controller: _localSearchCtrl,
            hintText: 'Tìm kiếm trong danh sách bạn bè...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_localSearchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _localSearchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
            ],
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHighest.withValues(alpha: 0.3)),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _ctrl.loadFriends();
            },
            child: filteredFriends.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Không tìm thấy bạn bè phù hợp trong danh sách.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredFriends.length,
                    itemBuilder: (_, i) {
                      final friend = filteredFriends[i];
                      return FriendTile(
                        friend: friend,
                        onTap: () => UserProfileBottomSheet.show(context, friend.user, _ctrl),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
                          onSelected: (val) async {
                            if (val == 'view_profile') {
                              UserProfileBottomSheet.show(context, friend.user, _ctrl);
                            } else if (val == 'unfriend') {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await _ctrl.unfriend(friend.friendshipId);
                              if (!ok) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(_ctrl.error ?? 'Đã xảy ra lỗi'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'view_profile', child: Text('Xem hồ sơ')),
                            const PopupMenuItem(value: 'unfriend', child: Text('Hủy kết bạn')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFriendsTab(ThemeData theme, ColorScheme cs) {
    final isSearchingActive = _globalSearchCtrl.text.isNotEmpty;

    return Column(
      children: [
        // Global Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SearchBar(
            controller: _globalSearchCtrl,
            hintText: 'Tìm người dùng bằng tên hoặc email...',
            leading: const Icon(Icons.person_search_outlined),
            onChanged: (q) => _ctrl.searchUsers(q),
            trailing: [
              if (_globalSearchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _globalSearchCtrl.clear();
                    _ctrl.clearSearch();
                    FocusScope.of(context).unfocus();
                  },
                ),
            ],
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHighest.withValues(alpha: 0.3)),
          ),
        ),

        Expanded(
          child: Builder(
            builder: (context) {
              if (isSearchingActive) {
                return _buildSearchResultsSection(cs);
              }

              final hasPending = _ctrl.pendingRequests.isNotEmpty;
              final hasSent = _ctrl.sentRequests.isNotEmpty;

              return RefreshIndicator(
                onRefresh: () async {
                  await _ctrl.loadPendingRequests();
                  await _ctrl.loadSentRequests();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // A. Incoming Requests
                    if (hasPending) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Lời mời kết bạn (${_ctrl.pendingRequests.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ctrl.pendingRequests.length,
                        itemBuilder: (_, i) {
                          final req = _ctrl.pendingRequests[i];
                          return FriendRequestTile(
                            request: req,
                            isLoading: _loadingRequests.contains(req.id),
                            onAccept: () async {
                              setState(() => _loadingRequests.add(req.id));
                              await _ctrl.respondRequest(req.id, true);
                              setState(() => _loadingRequests.remove(req.id));
                            },
                            onReject: () async {
                              setState(() => _loadingRequests.add(req.id));
                              await _ctrl.respondRequest(req.id, false);
                              setState(() => _loadingRequests.remove(req.id));
                            },
                          );
                        },
                      ),
                    ],

                    // B. Outgoing Requests (Sent Requests)
                    if (hasSent) ...[
                      if (hasPending) const Divider(height: 32, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Lời mời đã gửi (${_ctrl.sentRequests.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ctrl.sentRequests.length,
                        itemBuilder: (_, i) {
                          final req = _ctrl.sentRequests[i];
                          final user = req.addressee;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.shadow.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        if (user.email != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email!,
                                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (_loadingRequests.contains(req.id))
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        setState(() => _loadingRequests.add(req.id));
                                        await _ctrl.unfriend(req.id);
                                        setState(() => _loadingRequests.remove(req.id));
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Đã thu hồi lời mời kết bạn.')),
                                        );
                                      },
                                      icon: const Icon(Icons.close, size: 14),
                                      label: const Text('Hủy'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cs.error,
                                        side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // C. Empty State
                    if (!hasPending && !hasSent) ...[
                      const SizedBox(height: 48),
                      Icon(Icons.person_add_alt_rounded, size: 72, color: cs.primary.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'Tìm kiếm & Kết bạn mới',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nhập tên hoặc email vào thanh tìm kiếm ở trên\nđể gửi lời mời kết bạn kết nối với mọi người!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsSection(ColorScheme cs) {
    if (_ctrl.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ctrl.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_ctrl.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _ctrl.searchUsers(_globalSearchCtrl.text),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ctrl.searchResults.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy người dùng',
        subtitle: 'Thử kiểm tra lại từ khóa hoặc tìm kiếm bằng email',
      );
    }

    return ListView.builder(
      itemCount: _ctrl.searchResults.length,
      itemBuilder: (_, i) {
        final user = _ctrl.searchResults[i];
        final isSent = _loadingRequests.contains(user.id) || user.friendshipStatus == 'PENDING';
        final isAccepted = user.friendshipStatus == 'ACCEPTED';

        return _UserSearchTile(
          user: user,
          isSent: isSent,
          isAccepted: isAccepted,
          onTap: () => UserProfileBottomSheet.show(context, user, _ctrl),
          onAdd: () async {
            final ok = await _ctrl.sendRequest(user.id);
            if (ok) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi lời mời kết bạn!')),
                );
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_ctrl.error ?? 'Lỗi'), backgroundColor: Colors.red),
              );
            }
          },
          onCancel: () async {
            final messenger = ScaffoldMessenger.of(context);
            final target = user.friendshipId ?? user.id;
            final ok = await _ctrl.unfriend(target);
            if (ok) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã thu hồi lời mời kết bạn.')),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(content: Text(_ctrl.error ?? 'Lỗi'), backgroundColor: Colors.red),
              );
            }
          },
        );
      },
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  const _UserSearchTile({
    required this.user,
    required this.isSent,
    required this.isAccepted,
    required this.onTap,
    required this.onAdd,
    required this.onCancel,
  });

  final FriendUser user;
  final bool isSent;
  final bool isAccepted;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
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
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: user.email != null ? Text(user.email!) : null,
      trailing: isAccepted
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 12, color: cs.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Bạn bè',
                    style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : isSent
              ? OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.bold),
                  ),
                )
              : FilledButton.tonal(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Kết bạn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
