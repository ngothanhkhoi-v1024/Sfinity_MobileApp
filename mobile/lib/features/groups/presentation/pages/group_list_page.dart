import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../controllers/group_controller.dart';
import '../widgets/group_card.dart';
import '../widgets/discover_group_card.dart';
import '../widgets/group_empty_state.dart';
import '../widgets/group_error_state.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  late final GroupController _ctrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _ctrl = SfinityApp.groupController;
    _ctrl.loadMyGroups();
    _ctrl.loadDiscoverGroups();
    _ctrl.loadReceivedInvitations();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Nhóm học tập',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Bạn bè',
              onPressed: () => context.push(RouteNames.friends),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: cs.primary),
              tooltip: 'Tạo nhóm',
              onPressed: () => context.push(RouteNames.groupCreate),
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Nhóm của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Khám phá', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            indicatorWeight: 3.5,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyGroupsTab(context, cs),
            _buildDiscoverTab(context, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsTab(BuildContext context, ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        if (_ctrl.isLoading && _ctrl.groups.isEmpty && _ctrl.receivedInvitations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.error != null && _ctrl.groups.isEmpty && _ctrl.receivedInvitations.isEmpty) {
          return GroupErrorState(message: _ctrl.error!, onRetry: () {
            _ctrl.loadMyGroups();
            _ctrl.loadReceivedInvitations();
          });
        }

        final invites = _ctrl.receivedInvitations;
        final myGroups = _ctrl.groups;

        if (myGroups.isEmpty && invites.isEmpty) {
          return GroupEmptyState(onCreateGroup: () => context.push(RouteNames.groupCreate));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _ctrl.loadMyGroups(),
              _ctrl.loadReceivedInvitations(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ─── Danh sách lời mời nhóm đã nhận ───
              if (invites.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.mail_outline_rounded, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Lời mời tham gia nhóm học tập (${invites.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                ...invites.map((inv) {
                  final inviteId = inv['id']?.toString() ?? '';
                  final groupName = inv['groupName']?.toString() ?? 'Nhóm học tập';
                  final inviterName = inv['inviterName']?.toString() ?? 'Ai đó';
                  final avatarUrl = inv['groupAvatarUrl']?.toString();

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              backgroundColor: cs.primary.withValues(alpha: 0.1),
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                                    height: 1.3,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: inviterName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const TextSpan(text: ' mời bạn tham gia nhóm '),
                                    TextSpan(
                                      text: '"$groupName"',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Nút Từ chối (Decline)
                            OutlinedButton(
                              onPressed: () async {
                                final ok = await _ctrl.respondToInvitation(inviteId, false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Đã từ chối lời mời vào nhóm "$groupName"'
                                          : 'Từ chối lời mời thất bại. Vui lòng thử lại.'),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.black54,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                side: BorderSide(
                                  color: isDark ? Colors.white.withValues(alpha: 0.15) : cs.outlineVariant,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            // Nút Chấp nhận (Accept)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [cs.primary, const Color(0xFFFF5A36)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final ok = await _ctrl.respondToInvitation(inviteId, true);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? 'Chúc mừng! Bạn đã gia nhập nhóm "$groupName"'
                                            : 'Gia nhập nhóm thất bại. Vui lòng thử lại.'),
                                        backgroundColor: ok ? Colors.green.shade700 : null,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Chấp nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),
              ],

              // ─── Danh sách các nhóm học tập của tôi ───
              if (myGroups.isEmpty && invites.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.group_outlined, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'Bạn chưa tham gia nhóm nào.\nHãy đồng ý lời mời hoặc tạo nhóm mới!',
                        style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ...myGroups.map(
                (g) => GroupCard(
                  group: g,
                  onTap: () => context.push(
                    RouteNames.groupDetail.replaceFirst(':id', g.id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoverTab(BuildContext context, ColorScheme cs) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final filteredGroups = _ctrl.discoverGroups.where((g) {
          if (_searchQuery.isEmpty) return true;
          return g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (g.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return RefreshIndicator(
          onRefresh: _ctrl.loadDiscoverGroups,
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm nhóm học tập công khai...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_ctrl.isDiscoverLoading && filteredGroups.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_ctrl.error != null && filteredGroups.isEmpty) {
                      return GroupErrorState(
                        message: _ctrl.error!,
                        onRetry: _ctrl.loadDiscoverGroups,
                      );
                    }
                    if (filteredGroups.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: cs.outline),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Không có nhóm mới để khám phá'
                                  : 'Không tìm thấy nhóm phù hợp',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredGroups.length,
                      itemBuilder: (_, i) {
                        final group = filteredGroups[i];
                        return DiscoverGroupCard(
                          group: group,
                          onJoin: () async {
                            final success = await _ctrl.joinGroup(group.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? (group.autoApprove
                                            ? 'Đã gia nhập "${group.name}" thành công!'
                                            : 'Yêu cầu gia nhập "${group.name}" đã được gửi và đang chờ duyệt!')
                                        : (_ctrl.error ?? 'Đã có lỗi xảy ra'),
                                  ),
                                  backgroundColor: success ? Colors.green.shade700 : cs.error,
                                ),
                              );
                            }
                          },
                          onCancel: () async {
                            final success = await _ctrl.leaveGroup(group.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Đã hủy yêu cầu tham gia "${group.name}"!'
                                        : (_ctrl.error ?? 'Đã có lỗi xảy ra'),
                                  ),
                                  backgroundColor: success ? Colors.blue.shade700 : cs.error,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


}
