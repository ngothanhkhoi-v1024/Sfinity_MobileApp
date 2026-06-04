import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../shared/widgets/floating_pill_nav_bar.dart';
import '../../../document/presentation/pages/document_list_page.dart';
import 'community_page.dart';
import '../../../places/presentation/pages/places_map_page.dart';
import '../../../places/presentation/places_map_focus.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'explore_page.dart';

/// Shell chính: pill nav với 5 tab (Khám phá, Địa điểm, Tài liệu, Cộng đồng, Cá nhân).
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  /// 0 Khám phá, 1 Địa điểm, 2 Tài liệu, 3 Cộng đồng, 4 Cá nhân.
  late int _navIndex;

  late final List<Widget> _pages = const [
    ExplorePage(),
    PlacesMapPage(),
    DocumentListPage(embedded: true),
    CommunityPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialTab;
    PlacesMapFocus.pending.addListener(_onPlacesMapFocus);
  }

  @override
  void dispose() {
    PlacesMapFocus.pending.removeListener(_onPlacesMapFocus);
    super.dispose();
  }

  void _onPlacesMapFocus() {
    if (PlacesMapFocus.pending.value == null || !mounted) return;
    if (_navIndex != 1) {
      setState(() => _navIndex = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navItems = [
      PillNavItem(label: l10n.explore, icon: Icons.explore_outlined, selectedIcon: Icons.explore),
      PillNavItem(label: l10n.places, icon: Icons.map_outlined, selectedIcon: Icons.map),
      PillNavItem(label: l10n.documents, icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book),
      PillNavItem(label: l10n.community, icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt),
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
      appBar: (_navIndex == 1 || _navIndex == 3)
          ? null // Places and Community pages have their own AppBar
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
                if (_navIndex == 2)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Tooltip(
                      message: l10n.uploadDocument,
                      child: Material(
                        color: Colors.transparent,
                        child: Ink(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: isDark ? 0.24 : 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push(
                              RouteNames.documentCreate,
                              extra: const {'contentType': 'document'},
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_rounded,
                                color: cs.primary,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      body: IndexedStack(
        index: _navIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + bottomInset),
        child: FloatingPillNavBar(
          selectedIndex: _navIndex,
          items: navItems,
          onTabSelected: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }

  String _titleForNavIndex(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.explore,
      2 => l10n.documents,
      3 => l10n.community,
      4 => l10n.profile,
      _ => l10n.appName,
    };
  }
}
