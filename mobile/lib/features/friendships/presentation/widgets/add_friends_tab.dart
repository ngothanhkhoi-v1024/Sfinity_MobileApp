import 'package:flutter/material.dart';
import '../controllers/friendship_controller.dart';
import 'friend_request_tile.dart';
import 'user_profile_bottom_sheet.dart';
import 'user_search_tile.dart';
import 'friendships_empty_state.dart';

class AddFriendsTab extends StatefulWidget {
  const AddFriendsTab({super.key, required this.controller});
  final FriendshipController controller;

  @override
  State<AddFriendsTab> createState() => _AddFriendsTabState();
}

class _AddFriendsTabState extends State<AddFriendsTab> {
  final _globalSearchCtrl = TextEditingController();
  final Set<String> _loadingRequests = {};

  @override
  void dispose() {
    _globalSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = widget.controller;
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
            onChanged: (q) => ctrl.searchUsers(q),
            trailing: [
              if (_globalSearchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _globalSearchCtrl.clear();
                    ctrl.clearSearch();
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

              final hasPending = ctrl.pendingRequests.isNotEmpty;
              final hasSent = ctrl.sentRequests.isNotEmpty;

              return RefreshIndicator(
                onRefresh: () async {
                  await ctrl.loadPendingRequests();
                  await ctrl.loadSentRequests();
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
                              'Lời mời kết bạn (${ctrl.pendingRequests.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.pendingRequests.length,
                        itemBuilder: (_, i) {
                          final req = ctrl.pendingRequests[i];
                          return FriendRequestTile(
                            request: req,
                            isLoading: _loadingRequests.contains(req.id),
                            onAccept: () async {
                              setState(() => _loadingRequests.add(req.id));
                              await ctrl.respondRequest(req.id, true);
                              setState(() => _loadingRequests.remove(req.id));
                            },
                            onReject: () async {
                              setState(() => _loadingRequests.add(req.id));
                              await ctrl.respondRequest(req.id, false);
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
                              'Lời mời đã gửi (${ctrl.sentRequests.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.sentRequests.length,
                        itemBuilder: (_, i) {
                          final req = ctrl.sentRequests[i];
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
                                        await ctrl.unfriend(req.id);
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
    final ctrl = widget.controller;

    if (ctrl.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ctrl.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(ctrl.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ctrl.searchUsers(_globalSearchCtrl.text),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (ctrl.searchResults.isEmpty) {
      return const FriendshipsEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy người dùng',
        subtitle: 'Thử kiểm tra lại từ khóa hoặc tìm kiếm bằng email',
      );
    }

    return ListView.builder(
      itemCount: ctrl.searchResults.length,
      itemBuilder: (_, i) {
        final user = ctrl.searchResults[i];
        final isSent = _loadingRequests.contains(user.id) || user.friendshipStatus == 'PENDING';
        final isAccepted = user.friendshipStatus == 'ACCEPTED';

        return UserSearchTile(
          user: user,
          isSent: isSent,
          isAccepted: isAccepted,
          onTap: () => UserProfileBottomSheet.show(context, user, ctrl),
          onAdd: () async {
            final ok = await ctrl.sendRequest(user.id);
            if (ok) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi lời mời kết bạn!')),
                );
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ctrl.error ?? 'Lỗi'), backgroundColor: Colors.red),
              );
            }
          },
          onCancel: () async {
            final messenger = ScaffoldMessenger.of(context);
            final target = user.friendshipId ?? user.id;
            final ok = await ctrl.unfriend(target);
            if (ok) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã thu hồi lời mời kết bạn.')),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(content: Text(ctrl.error ?? 'Lỗi'), backgroundColor: Colors.red),
              );
            }
          },
        );
      },
    );
  }
}
