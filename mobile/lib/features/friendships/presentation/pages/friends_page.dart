import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../controllers/friendship_controller.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm bạn bè',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          return AddFriendsTab(controller: _ctrl);
        },
      ),
    );
  }
}
