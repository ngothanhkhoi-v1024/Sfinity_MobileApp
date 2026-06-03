import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../controllers/friendship_controller.dart';
import 'friend_tile.dart';
import 'user_profile_bottom_sheet.dart';
import 'friendships_empty_state.dart';

class FriendsListTab extends StatefulWidget {
  const FriendsListTab({super.key, required this.controller});
  final FriendshipController controller;

  @override
  State<FriendsListTab> createState() => _FriendsListTabState();
}

class _FriendsListTabState extends State<FriendsListTab> {
  final _localSearchCtrl = TextEditingController();
  String _localFilter = '';

  @override
  void initState() {
    super.initState();
    _localSearchCtrl.addListener(() {
      setState(() {
        _localFilter = _localSearchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _localSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = widget.controller;

    if (ctrl.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final friends = ctrl.friends;
    final filteredFriends = friends.where((f) {
      if (_localFilter.isEmpty) return true;
      final name = f.user.name.toLowerCase();
      final email = f.user.email?.toLowerCase() ?? '';
      return name.contains(_localFilter) || email.contains(_localFilter);
    }).toList();

    if (friends.isEmpty) {
      return FriendshipsEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Chưa có bạn bè',
        subtitle: 'Tìm kiếm và gửi lời mời kết bạn để kết nối nhé!',
        actionLabel: 'Thêm bạn bè',
        onAction: () => context.push(RouteNames.friends),
      );
    }

    return Column(
      children: [
        // Local Filter Search Bar with Add Friend shortcut button next to it
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
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
                  backgroundColor: WidgetStatePropertyAll(
                    cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: () => context.push(RouteNames.friends),
                tooltip: 'Thêm bạn bè',
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ctrl.loadFriends();
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
                        onTap: () => UserProfileBottomSheet.show(
                          context,
                          friend.user,
                          ctrl,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            color: cs.onSurfaceVariant,
                          ),
                          onSelected: (val) async {
                            if (val == 'view_profile') {
                              UserProfileBottomSheet.show(
                                context,
                                friend.user,
                                ctrl,
                              );
                            } else if (val == 'unfriend') {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await ctrl.unfriend(
                                friend.friendshipId,
                              );
                              if (!ok) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ctrl.error ?? 'Đã xảy ra lỗi',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'view_profile',
                              child: Text('Xem hồ sơ'),
                            ),
                            const PopupMenuItem(
                              value: 'unfriend',
                              child: Text('Hủy kết bạn'),
                            ),
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
}
