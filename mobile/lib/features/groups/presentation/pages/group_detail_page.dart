import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/auth/auth_state.dart';
import '../../data/models/group_model.dart';
import '../../data/services/group_chat_service.dart';
import '../controllers/group_controller.dart';
import '../../../friendships/presentation/controllers/friendship_controller.dart';
import '../widgets/group_chat_tab.dart';
import '../widgets/group_files_tab.dart';
import '../widgets/group_members_tab.dart';
import '../widgets/invite_member_sheet.dart';
import '../widgets/share_document_sheet.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late final GroupController _groupCtrl;
  late final FriendshipController _friendCtrl;
  late final AuthState _auth;
  final _chatService = GroupChatService();

  String? _userName;
  String? _userAvatar;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _groupCtrl = SfinityApp.groupController;
    _friendCtrl = SfinityApp.friendshipController;
    _auth = SfinityApp.auth;
    _groupCtrl.loadGroup(widget.groupId);
    _friendCtrl.loadFriends();

    _userId = _auth.user?['id']?.toString();
    _userName = _auth.user?['name']?.toString() ?? 'Bạn';
    _userAvatar = _auth.user?['avatar']?.toString();
  }

  String get _myUid => _userId ?? '';

  Future<void> _showShareDocumentSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ShareDocumentSheet(
        onShare: (docId, docTitle) async {
          Navigator.pop(ctx);
          if (_userId == null) return;
          await _chatService.shareDocument(
            groupId: widget.groupId,
            senderId: _userId!,
            senderName: _userName ?? 'Bạn',
            senderAvatar: _userAvatar,
            documentId: docId,
            documentTitle: docTitle,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _groupCtrl,
      builder: (context, _) {
        final group = _groupCtrl.currentGroup;
        if (_groupCtrl.isLoading && group == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Không tìm thấy nhóm học tập')),
          );
        }
        final cs = Theme.of(context).colorScheme;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: cs.brightness == Brightness.dark ? const Color(0xFF0A0A0A) : cs.surface,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(context, group, innerBoxIsScrolled),
                ];
              },
              body: TabBarView(
                children: [
                  GroupChatTab(
                    groupId: group.id,
                    userId: _myUid,
                    userName: _userName ?? 'Bạn',
                    userAvatar: _userAvatar,
                    onShareDocument: _showShareDocumentSheet,
                  ),
                  GroupFilesTab(
                    groupId: group.id,
                    onShareDocument: _showShareDocumentSheet,
                  ),
                  GroupMembersTab(
                    group: group,
                    myUid: _myUid,
                    onInviteMember: () => _showInviteMemberSheet(context, group),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, GroupModel group, bool innerBoxIsScrolled) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : cs.surface,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : cs.onSurface,
          size: 24,
        ),
        onPressed: () => context.pop(),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.name,
                style: TextStyle(
                  color: isDark ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: group.isPublic ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  group.isPublic ? 'CÔNG KHAI' : 'RIÊNG TƯ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${group.memberCount} thành viên • ${group.memberCount ~/ 3 + 1} đang online',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white.withValues(alpha: 0.55) : cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark ? Colors.white : cs.onSurface,
            size: 24,
          ),
          onPressed: () => _showGroupSettingsBottomSheet(context, group),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : cs.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : cs.outlineVariant.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: isDark ? Colors.white : cs.primary,
            unselectedLabelColor: isDark ? Colors.white.withValues(alpha: 0.5) : cs.onSurfaceVariant.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
            tabs: const [
              Tab(text: 'Trò chuyện'),
              Tab(text: 'Tài liệu'),
              Tab(text: 'Thành viên'),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupSettingsBottomSheet(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final isOwnerOrAdmin = group.isAdmin || group.members.any((m) => m.user.id == _userId && (m.role == 'OWNER' || m.role == 'ADMIN'));

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : cs.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Text(
                  'Tùy chọn nhóm học tập',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : cs.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              if (isOwnerOrAdmin) ...[
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: isDark ? Colors.white.withValues(alpha: 0.7) : cs.onSurfaceVariant),
                  title: const Text('Chỉnh sửa thông tin nhóm', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, group);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_add_outlined, color: isDark ? Colors.white.withValues(alpha: 0.7) : cs.onSurfaceVariant),
                  title: const Text('Thêm thành viên', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _showInviteMemberSheet(context, group);
                  },
                ),
              ],
              if (group.isOwner)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                  title: Text('Giải tán nhóm', style: TextStyle(color: cs.error, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, group);
                  },
                ),
              if (!group.isOwner)
                ListTile(
                  leading: Icon(Icons.exit_to_app_rounded, color: cs.error),
                  title: Text('Rời khỏi nhóm', style: TextStyle(color: cs.error, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLeave(context, group);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showInviteMemberSheet(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InviteMemberSheet(
        group: group,
        groupCtrl: _groupCtrl,
        friendCtrl: _friendCtrl,
      ),
    );
  }

  // ─── DIALOGS & HELPER METHODS ──────────────────────────────────────────────

  Future<void> _showEditDialog(BuildContext context, GroupModel group) async {
    final nameCtrl = TextEditingController(text: group.name);
    final descCtrl = TextEditingController(text: group.description ?? '');
    bool isPublic = group.isPublic;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Chỉnh sửa nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên nhóm', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Nhóm công khai'),
                value: isPublic,
                onChanged: (v) => setSt(() => isPublic = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                await _groupCtrl.updateGroup(
                  group.id,
                  name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  isPublic: isPublic,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, GroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rời nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn rời nhóm học tập "${group.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _groupCtrl.leaveGroup(group.id);
      if (context.mounted) {
        if (ok) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_groupCtrl.error ?? 'Lỗi')));
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, GroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa nhóm "${group.name}"? Tất cả lịch sử tin nhắn sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa nhóm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _groupCtrl.deleteGroup(group.id);
      if (context.mounted) {
        if (ok) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_groupCtrl.error ?? 'Lỗi')));
        }
      }
    }
  }
}
