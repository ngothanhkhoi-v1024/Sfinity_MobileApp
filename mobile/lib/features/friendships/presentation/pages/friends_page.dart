import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../controllers/friendship_controller.dart';
import '../widgets/friends_list_tab.dart';
import '../widgets/add_friends_tab.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final FriendshipController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SfinityApp.friendshipController;
    _ctrl.loadFriends();
    _ctrl.loadPendingRequests();
    _ctrl.loadSentRequests();
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
                FriendsListTab(controller: _ctrl),
                AddFriendsTab(controller: _ctrl),
              ],
            );
          },
        ),
      ),
    );
  }
}
