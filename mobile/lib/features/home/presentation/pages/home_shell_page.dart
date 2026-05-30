import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
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
    final l10n = context.l10n;
    final navItems = [
      PillNavItem(label: l10n.explore, icon: Icons.explore_outlined, selectedIcon: Icons.explore),
      PillNavItem(label: l10n.places, icon: Icons.map_outlined, selectedIcon: Icons.map),
      PillNavItem(label: l10n.documents, icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book),
      PillNavItem(label: l10n.profile, icon: Icons.person_outline, selectedIcon: Icons.person),
    ];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(l10n.appName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l10n.shareDescription, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(l10n.search),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.search);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text(l10n.saved),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.favorites);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.notifications),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.notifications);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settings),
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
                      title: Text(_titleForNavIndex(context, _navIndex)),
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
            items: navItems,
          onTabSelected: (i) {
            if (i == FloatingPillNavBar.centerSlotIndex) return;
            setState(() => _navIndex = i);
          },
          onCenterTap: () => showShareActionSheet(context),
        ),
      ),
    );
  }

  String _titleForNavIndex(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.explore,
      3 => l10n.documents,
      4 => l10n.profile,
      _ => l10n.appName,
    };
  }
}
