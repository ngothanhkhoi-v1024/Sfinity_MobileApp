import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
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
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: AnimatedBuilder(
          animation: SfinityApp.auth,
          builder: (context, _) {
            final user = SfinityApp.auth.user;
            final hasUser = user != null;
            final avatarUrl = user?['avatar']?.toString();
            final displayName = user?['name']?.toString() ?? '';
            final email = user?['email']?.toString() ?? '';
            final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
            final initial = (displayName.isNotEmpty ? displayName : 'U')[0].toUpperCase();

            return Column(
              children: [
                // Brand and Profile Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 24),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandHeader(context),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandPill(context),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryOf(context).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.appName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  letterSpacing: -0.5,
                                  color: AppColors.title(context),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          l10n.shareDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasUser) ...[
                        const SizedBox(height: 20),
                        Material(
                          color: AppColors.card(context).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              context.push(RouteNames.viewProfile);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.border(context).withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryOf(context).withValues(alpha: 0.15),
                                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                                    child: hasAvatar
                                        ? null
                                        : Text(
                                            initial,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryOf(context),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName.isNotEmpty ? displayName : 'User',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (email.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted(context),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.muted(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Menu List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    children: [
                      _buildDrawerItem(
                        context,
                        icon: Icons.search_rounded,
                        label: l10n.search,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(RouteNames.search);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.bookmark_rounded,
                        label: l10n.saved,
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(RouteNames.favorites);
                        },
                      ),
                      if (hasUser)
                        _buildDrawerItem(
                          context,
                          icon: Icons.article_rounded,
                          label: l10n.myPosts,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.pop(context);
                            context.push(RouteNames.myDocuments);
                          },
                        ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.settings_rounded,
                        label: l10n.settings,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(RouteNames.settings);
                        },
                      ),
                    ],
                  ),
                ),
                
                // Sign Out or Sign In
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 16),
                  child: hasUser
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              Navigator.pop(context);
                              await SfinityApp.auth.logout();
                              if (context.mounted) context.go(RouteNames.login);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.signOut,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: Text(l10n.login),
                            onPressed: () {
                              Navigator.pop(context);
                              context.go(RouteNames.login);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
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
                if (_navIndex == 0)
                  AnimatedBuilder(
                    animation: SfinityApp.auth,
                    builder: (context, _) {
                      final user = SfinityApp.auth.user;
                      final hasUser = user != null;
                      final avatarUrl = user?['avatar']?.toString();
                      final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                      final displayName = user?['name']?.toString() ?? '';
                      final initial = (displayName.isNotEmpty ? displayName : 'U')[0].toUpperCase();

                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (hasUser) {
                                context.push(RouteNames.viewProfile);
                              } else {
                                context.push(RouteNames.login);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.primary.withValues(alpha: 0.15),
                                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                                child: hasAvatar
                                    ? null
                                    : Text(
                                        initial,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDark ? color.withValues(alpha: 0.9) : color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.title(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.muted(context).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
