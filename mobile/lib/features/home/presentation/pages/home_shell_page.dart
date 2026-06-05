import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bar_add_button.dart';
import '../../../../shared/widgets/floating_pill_nav_bar.dart';
import '../../../assistant/presentation/widgets/assistant_chat_sheet.dart';
import '../../../assistant/presentation/widgets/assistant_context_hint.dart';
import '../../../assistant/presentation/widgets/assistant_fab.dart';
import '../../../document/presentation/pages/document_list_page.dart';
import 'community_page.dart';
import '../../../places/presentation/pages/places_map_page.dart';
import '../../../places/presentation/places_map_focus.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'explore_page.dart';

final GlobalKey<HomeShellPageState> homeShellKey = GlobalKey<HomeShellPageState>();

/// Shell chính: pill nav với 5 tab (Khám phá, Địa điểm, Tài liệu, Cộng đồng, Cá nhân).
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HomeShellPage> createState() => HomeShellPageState();
}

class HomeShellPageState extends State<HomeShellPage> {
  /// 0 Khám phá, 1 Địa điểm, 2 Tài liệu, 3 Cộng đồng, 4 Cá nhân.
  late int _navIndex;
  int _unreadCount = 0;
  bool _showContextHint = false;
  String _currentContextId = 'explore';

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
    _currentContextId = _contextForTab(_navIndex);
    PlacesMapFocus.pending.addListener(_onPlacesMapFocus);
    SfinityApp.auth.addListener(_onAuthChanged);
    _loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkContextHint());
  }

  @override
  void dispose() {
    SfinityApp.auth.removeListener(_onAuthChanged);
    PlacesMapFocus.pending.removeListener(_onPlacesMapFocus);
    super.dispose();
  }

  void _onAuthChanged() {
    if (SfinityApp.auth.isAuthenticated) {
      _loadUnreadCount();
      _checkContextHint();
    } else {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _showContextHint = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    if (!SfinityApp.notificationManager.enabled || !SfinityApp.auth.isAuthenticated) return;
    try {
      final items = await ApiClient.instance.getList('/notifications');
      if (!mounted) return;
      int unread = 0;
      for (final n in items) {
        if (n is Map && n['read'] != true) unread++;
      }
      setState(() => _unreadCount = unread);
    } catch (e) {
      // ignore
    }
  }

  void _onPlacesMapFocus() {
    if (PlacesMapFocus.pending.value == null || !mounted) return;
    if (_navIndex != 1) {
      setState(() => _navIndex = 1);
    }
  }

  void switchTab(int index) {
    if (_navIndex != index && mounted) {
      setState(() => _navIndex = index);
      _onTabChanged(index);
    }
  }

  String _contextForTab(int index) {
    return switch (index) {
      0 => 'explore',
      1 => 'places',
      2 => 'documents',
      3 => 'community',
      4 => 'profile',
      _ => 'explore',
    };
  }

  void _onTabChanged(int index) {
    final contextId = _contextForTab(index);
    _currentContextId = contextId;
    SfinityApp.assistantController.setContext(contextId);
    _checkContextHint();
  }

  void _checkContextHint() {
    if (!SfinityApp.auth.isAuthenticated) {
      if (_showContextHint) setState(() => _showContextHint = false);
      return;
    }
    final seen = SfinityApp.assistantHintManager.hasSeenContext(_currentContextId);
    if (mounted && _showContextHint != !seen) {
      setState(() => _showContextHint = !seen);
    }
  }

  void _dismissContextHint() {
    SfinityApp.assistantHintManager.markContextSeen(_currentContextId);
    if (mounted) setState(() => _showContextHint = false);
  }

  void _openAssistantChat() {
    _dismissContextHint();
    AssistantChatSheet.show(context, contextId: _currentContextId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
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
                Padding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.shareDescription,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted(context),
                          height: 1.35,
                        ),
                      ),
                      if (hasUser) ...[
                        const SizedBox(height: 16),
                        Material(
                          color: AppColors.card(context),
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
                                border: Border.all(color: AppColors.border(context)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryTint(context),
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName.isNotEmpty ? displayName : 'User',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.title(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (email.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              fontSize: 11.5,
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
                Divider(height: 1, color: AppColors.divider(context)),
                
                // Menu List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    children: [
                      Container(
                        decoration: AppColors.panel(context),
                        child: Column(
                          children: [
                            _buildDrawerItem(
                              context,
                              icon: Icons.manage_search_rounded,
                              label: l10n.quickLookup,
                              onTap: () {
                                Navigator.pop(context);
                                context.push(RouteNames.search);
                              },
                              showDivider: true,
                            ),
                            _buildDrawerItem(
                              context,
                              icon: Icons.bookmark_outline_rounded,
                              label: l10n.saved,
                              onTap: () {
                                Navigator.pop(context);
                                context.push(RouteNames.favorites);
                              },
                              showDivider: hasUser,
                            ),
                            if (hasUser)
                              _buildDrawerItem(
                                context,
                                icon: Icons.article_outlined,
                                label: l10n.myPosts,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push(RouteNames.myDocuments);
                                },
                                showDivider: true,
                              ),
                            _buildDrawerItem(
                              context,
                              icon: Icons.settings_outlined,
                              label: l10n.settings,
                              onTap: () {
                                Navigator.pop(context);
                                context.push(RouteNames.settings);
                              },
                            ),
                          ],
                        ),
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

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasUser)
                            IconButton(
                              onPressed: () {
                                context.push(RouteNames.notifications).then((_) {
                                  _loadUnreadCount();
                                });
                              },
                              icon: Badge(
                                isLabelVisible: _unreadCount > 0,
                                label: Text(_unreadCount.toString()),
                                child: const Icon(Icons.notifications_none_rounded),
                              ),
                            ),
                          Padding(
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
                          ),
                        ],
                      );
                    },
                  ),
                if (_navIndex == 2)
                  AppBarAddButton(
                    tooltip: l10n.uploadDocument,
                    onPressed: () => context.push(
                      RouteNames.documentCreate,
                      extra: const {'contentType': 'document'},
                    ),
                  ),
              ],
            ),
      body: Stack(
        children: [
          IndexedStack(
            index: _navIndex,
            children: _pages,
          ),
          if (SfinityApp.auth.isAuthenticated)
            Positioned(
              right: 16,
              bottom: 88 + bottomInset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_showContextHint)
                    AssistantContextHint(
                      onOpenChat: _openAssistantChat,
                      onDismiss: _dismissContextHint,
                    ),
                  AssistantFab(onTap: _openAssistantChat),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset),
        child: FloatingPillNavBar(
          selectedIndex: _navIndex,
          items: navItems,
          onTabSelected: (i) {
            setState(() => _navIndex = i);
            _onTabChanged(i);
          },
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
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.chipBg(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.title(context)),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: AppColors.title(context),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.muted(context),
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 62, color: AppColors.divider(context)),
      ],
    );
  }
}
