import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../shared/widgets/floating_pill_nav_bar.dart';
import '../../../../shared/widgets/share_action_sheet.dart';
import '../../../document/presentation/pages/document_list_page.dart';
import '../../../places/presentation/pages/places_map_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'explore_page.dart';

/// Shell chính: pill nav + nút chia sẻ giữa + tab Địa điểm (OSM).
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  /// Chỉ số thanh nav: 0 Khám phá, 1 Địa điểm, 3 Tài liệu, 4 Cá nhân.
  int _navIndex = 0;

  static const _navItems = [
    PillNavItem(
      label: 'Khám phá',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
    ),
    PillNavItem(
      label: 'Địa điểm',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
    ),
    PillNavItem(
      label: 'Tài liệu',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    PillNavItem(
      label: 'Cá nhân',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  int get _pageIndex {
    if (_navIndex <= 1) return _navIndex;
    return _navIndex - 1;
  }

  late final List<Widget> _pages = const [
    ExplorePage(),
    PlacesMapPage(),
    DocumentListPage(embedded: true),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Sfinity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Địa điểm & tài liệu học tập', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Tìm kiếm'),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.search);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Đã lưu'),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.favorites);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Thông báo'),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.notifications);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.settings);
              },
            ),
          ],
        ),
      ),
      appBar: _navIndex == 1
          ? null
          : AppBar(
              title: Text(_titleForNavIndex(_navIndex)),
              leading: _navIndex == 0
                  ? Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    )
                  : null,
              automaticallyImplyLeading: _navIndex == 0,
              actions: [
                if (_navIndex == 3)
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 26),
                    onPressed: () => context.push(
                      RouteNames.documentCreate,
                      extra: const {'contentType': 'document'},
                    ),
                  ),
              ],
            ),
      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + bottomInset),
        child: FloatingPillNavBar(
          selectedIndex: _navIndex,
          items: _navItems,
          onTabSelected: (i) {
            if (i == FloatingPillNavBar.centerSlotIndex) return;
            setState(() => _navIndex = i);
          },
          onCenterTap: () => showShareActionSheet(context),
        ),
      ),
    );
  }

  String _titleForNavIndex(int index) {
    return switch (index) {
      0 => 'Khám phá',
      3 => 'Tài liệu',
      4 => 'Cá nhân',
      _ => 'Sfinity',
    };
  }
}
