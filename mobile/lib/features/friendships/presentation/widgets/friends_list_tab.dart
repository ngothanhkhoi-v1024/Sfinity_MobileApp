import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/constants/route_names.dart';
import '../controllers/friendship_controller.dart';
import '../../../places/presentation/widgets/places_search_field.dart';
import 'friend_tile.dart';
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
    final l10n = context.l10n;

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
        title: l10n.noFriends,
        subtitle: l10n.noFriendsSearchHint,
        actionLabel: l10n.addFriends,
        onAction: () => context.push(RouteNames.friends),
      );
    }

    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: PlacesSearchField(
                  controller: _localSearchCtrl,
                  hint: l10n.searchFriends,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: cs.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => context.push(RouteNames.friends),
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.person_add_rounded, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: () async {
              await ctrl.loadFriends();
            },
            child: filteredFriends.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.noFriendsFound,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredFriends.length,
                    itemBuilder: (_, i) {
                      final friend = filteredFriends[i];
                      return FriendTile(
                        friend: friend,
                        onTap: () => context.push(
                          RouteNames.viewProfile,
                          extra: friend.user,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            color: cs.onSurfaceVariant,
                          ),
                          onSelected: (val) async {
                            if (val == 'view_profile') {
                              context.push(
                                RouteNames.viewProfile,
                                extra: friend.user,
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
                                      ctrl.error ?? l10n.friendRequestError,
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'view_profile',
                              child: Text(l10n.viewProfile),
                            ),
                            PopupMenuItem(
                              value: 'unfriend',
                              child: Text(l10n.unfriend),
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
