import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../data/models/group_model.dart';
import '../controllers/group_controller.dart';
import '../widgets/group_card.dart';
import '../widgets/discover_group_card.dart';

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
              onPressed: () => _showCreateDialog(context),
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
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        if (_ctrl.isLoading && _ctrl.groups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.error != null && _ctrl.groups.isEmpty) {
          return _ErrorState(message: _ctrl.error!, onRetry: _ctrl.loadMyGroups);
        }
        if (_ctrl.groups.isEmpty) {
          return _EmptyState(onCreateGroup: () => _showCreateDialog(context));
        }
        return RefreshIndicator(
          onRefresh: _ctrl.loadMyGroups,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _ctrl.groups.length,
            itemBuilder: (_, i) => GroupCard(
              group: _ctrl.groups[i],
              onTap: () => context.push(
                RouteNames.groupDetail.replaceFirst(':id', _ctrl.groups[i].id),
              ),
            ),
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
                      return _ErrorState(
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
                                        ? 'Đã gia nhập "${group.name}" thành công!'
                                        : (_ctrl.error ?? 'Đã có lỗi xảy ra'),
                                  ),
                                  backgroundColor: success ? Colors.green.shade700 : cs.error,
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

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isPublic = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Tạo nhóm mới', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên nhóm *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Nhóm công khai'),
                subtitle: const Text('Bất kỳ ai cũng có thể tìm và gia nhập'),
                value: isPublic,
                onChanged: (v) => setSt(() => isPublic = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ListenableBuilder(
              listenable: _ctrl,
              builder: (_, __) => FilledButton(
                onPressed: _ctrl.isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final group = await _ctrl.createGroup(
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          isPublic: isPublic,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (group != null && context.mounted) {
                          context.push(RouteNames.groupDetail.replaceFirst(':id', group.id));
                        }
                      },
                child: _ctrl.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Tạo nhóm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateGroup});
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_outlined, size: 56, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text('Chưa có nhóm nào', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Tạo nhóm học tập hoặc chuyển sang Tab Khám phá để tham gia các nhóm học tập công khai ngay!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateGroup,
              icon: const Icon(Icons.add),
              label: const Text('Tạo nhóm mới'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
        ],
      ),
    );
  }
}
