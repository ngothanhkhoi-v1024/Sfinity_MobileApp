import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/auth/auth_state.dart';
import '../../data/models/group_model.dart';
import '../../data/models/friend_model.dart';
import '../../data/models/group_message_model.dart';
import '../../data/services/group_chat_service.dart';
import '../controllers/group_controller.dart';
import '../controllers/friendship_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/user_profile_bottom_sheet.dart';

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
  final _scrollCtrl = ScrollController();

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

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _myUid => _userId ?? '';

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (_userId == null) return;
    await _chatService.sendTextMessage(
      groupId: widget.groupId,
      senderId: _userId!,
      senderName: _userName ?? 'Bạn',
      senderAvatar: _userAvatar,
      text: text,
    );
    _scrollToBottom();
  }

  Future<void> _showShareDocumentSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ShareDocumentSheet(
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
          _scrollToBottom();
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
                  _buildChatTab(context, group),
                  _buildFilesTab(context, group),
                  _buildMembersTab(context, group),
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
      builder: (ctx) => _InviteMemberSheet(
        group: group,
        groupCtrl: _groupCtrl,
        friendCtrl: _friendCtrl,
      ),
    );
  }

  // ─── TAB 1: LIVE CHAT ──────────────────────────────────────────────────────
  Widget _buildChatTab(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.brightness == Brightness.dark ? const Color(0xFF0A0A0A) : cs.surface,
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GroupMessageModel>>(
              stream: _chatService.messagesStream(group.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Lỗi: ${snap.error}'));
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text('Chưa có tin nhắn nào', style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                          'Hãy là người đầu tiên gửi tin!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _userId;
                    final showAvatar = i == messages.length - 1 ||
                        messages[i + 1].senderId != msg.senderId;
                    return ChatBubble(
                      message: msg,
                      isMe: isMe,
                      showAvatar: showAvatar,
                    );
                  },
                );
              },
            ),
          ),
          ChatInputBar(
            onSend: _sendMessage,
            onShareDocument: _showShareDocumentSheet,
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: DOCUMENT SHARING ──────────────────────────────────────────────
  Widget _buildFilesTab(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.brightness == Brightness.dark ? const Color(0xFF0A0A0A) : cs.surface,
      child: StreamBuilder<List<GroupMessageModel>>(
        stream: _chatService.sharedDocumentsStream(group.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final docs = snap.data ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tài liệu học tập (${docs.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showShareDocumentSheet,
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Chia sẻ tài liệu'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 64,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text('Chưa có tài liệu nào', style: TextStyle(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text(
                              'Nhấn nút chia sẻ để đăng tài liệu lên nhóm!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final docMsg = docs[i];
                          final docId = docMsg.sharedDocumentId ?? '';
                          final docTitle = docMsg.sharedDocumentTitle ?? 'Tài liệu không tên';

                          return Card(
                            elevation: 0,
                            color: cs.surfaceContainerLowest,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              title: Text(
                                docTitle,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Chia sẻ bởi ${docMsg.senderName}',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onSurfaceVariant),
                                onPressed: () {
                                  context.push('/document/$docId');
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }


  // ─── TAB 4: MEMBER MANAGEMENT ──────────────────────────────────────────────
  Widget _buildMembersTab(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final isOwnerOrAdmin = group.isAdmin || group.members.any((m) => m.user.id == _userId && (m.role == 'OWNER' || m.role == 'ADMIN'));

    return Container(
      color: isDark ? const Color(0xFF0A0A0A) : cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Thành viên nhóm (${group.members.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: group.members.length + (isOwnerOrAdmin ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (isOwnerOrAdmin && i == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _showInviteMemberSheet(context, group),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: cs.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Thêm thành viên',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Mời bạn bè vào nhóm học tập này',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                final member = group.members[isOwnerOrAdmin ? i - 1 : i];
                return _MemberTile(
                  member: member,
                  myUid: _myUid,
                  isGroupAdmin: false,
                  isOwner: group.isOwner,
                  onRemove: null,
                );
              },
            ),
          ),
        ],
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


// ─── Member Tile Component ────────────────────────────────────────────────────
class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.myUid,
    required this.isGroupAdmin,
    required this.isOwner,
    this.onRemove,
  });
  final GroupMemberModel member;
  final String myUid;
  final bool isGroupAdmin;
  final bool isOwner;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMe = member.user.id == myUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: isMe
            ? null
            : () => UserProfileBottomSheet.show(
                  context,
                  member.user,
                  SfinityApp.friendshipController,
                ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          backgroundImage: member.user.avatar != null ? NetworkImage(member.user.avatar!) : null,
          backgroundColor: cs.primaryContainer,
          child: member.user.avatar == null
              ? Text(
                  member.user.name.isNotEmpty ? member.user.name[0].toUpperCase() : '?',
                  style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(member.user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (isMe) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Bạn',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: member.user.email != null
            ? Text(member.user.email!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11))
            : null,
        trailing: member.role == 'OWNER'
            ? Icon(Icons.star_rounded, color: Colors.amber.shade600)
            : member.role == 'ADMIN'
                ? Icon(Icons.shield_rounded, color: cs.primary)
                : (isGroupAdmin && !isMe && onRemove != null)
                    ? IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: cs.error, size: 20),
                        onPressed: onRemove,
                      )
                    : null,
      ),
    );
  }
}

// ─── Share Document Bottom Sheet ────────────────────────────────────────────
class _ShareDocumentSheet extends StatefulWidget {
  const _ShareDocumentSheet({required this.onShare});
  final Future<void> Function(String id, String title) onShare;

  @override
  State<_ShareDocumentSheet> createState() => _ShareDocumentSheetState();
}

class _ShareDocumentSheetState extends State<_ShareDocumentSheet> {
  List<dynamic> _docs = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _manualMode = false;

  final _idCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SfinityApp.documentRepository.getDocuments(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 30,
      );
      final items = res['items'] as List? ?? [];
      setState(() {
        _docs = items.where((e) {
          final itemMap = e as Map<String, dynamic>;
          final type = itemMap['type']?.toString();
          if (type != null) {
            return type == 'document';
          }
          final body = itemMap['body']?.toString() ?? '';
          return !body.contains('type:place');
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách tài liệu. Vui lòng thử lại.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chia sẻ tài liệu',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _manualMode = !_manualMode;
                  });
                },
                icon: Icon(_manualMode ? Icons.list_alt_rounded : Icons.edit_note_rounded),
                label: Text(_manualMode ? 'Chọn từ danh sách' : 'Nhập ID thủ công'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_manualMode) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idCtrl,
                      decoration: InputDecoration(
                        labelText: 'ID tài liệu',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tên tài liệu',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.picture_as_pdf_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final id = _idCtrl.text.trim();
                          final title = _titleCtrl.text.trim();
                          if (id.isEmpty || title.isEmpty) return;
                          await widget.onShare(id, title);
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Chia sẻ vào nhóm'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu học tập...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadDocs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onSubmitted: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
                _loadDocs();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: TextStyle(color: cs.error)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadDocs,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : _docs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy tài liệu nào',
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _docs.length,
                              itemBuilder: (ctx, i) {
                                final doc = _docs[i] as Map<String, dynamic>;
                                final docId = doc['id']?.toString() ?? '';
                                final docTitle = doc['title']?.toString() ?? 'Tài liệu không tên';
                                final subjectCode = doc['subjectCode']?.toString();
                                final category = (doc['category'] as Map?)?['name']?.toString() ?? 'Tài liệu';

                                return Card(
                                  elevation: 0,
                                  color: cs.surfaceContainerLowest,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.description_rounded,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      docTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${subjectCode != null ? "$subjectCode • " : ""}$category',
                                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                    trailing: TextButton.icon(
                                      onPressed: () async {
                                        await widget.onShare(docId, docTitle);
                                      },
                                      icon: const Icon(Icons.send_rounded, size: 14),
                                      label: const Text('Chia sẻ'),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Invite Member Bottom Sheet Widget ──────────────────────────────────────

class _InviteMemberSheet extends StatefulWidget {
  const _InviteMemberSheet({
    required this.group,
    required this.groupCtrl,
    required this.friendCtrl,
  });

  final GroupModel group;
  final GroupController groupCtrl;
  final FriendshipController friendCtrl;

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Map<String, bool> _sendingMap = {};

  void _onFriendCtrlChange() {
    if (mounted) setState(() {});
  }

  void _onGroupCtrlChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.groupCtrl.loadGroupInvitations(widget.group.id);
    widget.friendCtrl.loadFriends();
    widget.friendCtrl.addListener(_onFriendCtrlChange);
    widget.groupCtrl.addListener(_onGroupCtrlChange);
  }

  @override
  void dispose() {
    widget.friendCtrl.removeListener(_onFriendCtrlChange);
    widget.groupCtrl.removeListener(_onGroupCtrlChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // Xác định tập hợp các ID thành viên hiện tại để loại trừ/gắn nhãn
    final existingMemberIds = widget.group.members.map((m) => m.user.id).toSet();

    // Xác định tập hợp các ID có lời mời đang chờ (PENDING)
    final pendingInvitedIds = widget.groupCtrl.groupInvitations
        .where((inv) => inv['status'] == 'PENDING')
        .map((inv) => inv['inviteeId']?.toString() ?? '')
        .toSet();

    List<FriendUser> displayUsers = [];
    final isSearchingMode = _query.trim().length >= 2;

    if (isSearchingMode) {
      displayUsers = widget.friendCtrl.searchResults;
    } else {
      // Ô tìm kiếm trống -> hiển thị danh sách bạn bè gợi ý
      displayUsers = widget.friendCtrl.friends.map((f) => f.user).toList();
    }

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : cs.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mời thành viên',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : cs.onSurface,
                ),
              ),
              if (widget.friendCtrl.isSearching)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc email...',
              hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.35) : cs.onSurfaceVariant.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white.withValues(alpha: 0.4) : cs.onSurfaceVariant.withValues(alpha: 0.6)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                        widget.friendCtrl.clearSearch();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : cs.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            onChanged: (val) {
              setState(() => _query = val);
              // Kích hoạt tìm kiếm khi gõ >= 2 ký tự
              widget.friendCtrl.searchUsers(val);
            },
          ),
          const SizedBox(height: 16),
          Text(
            isSearchingMode ? 'Kết quả tìm kiếm' : 'Gợi ý từ bạn bè',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.45) : cs.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.friendCtrl.isSearching && displayUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : displayUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 48,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isSearchingMode ? 'Không tìm thấy người dùng nào' : 'Danh sách bạn bè trống',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayUsers.length,
                        itemBuilder: (ctx, i) {
                          final user = displayUsers[i];
                          final isMember = existingMemberIds.contains(user.id);
                          final hasPendingInvite = pendingInvitedIds.contains(user.id);
                          final isSending = _sendingMap[user.id] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.02) : cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.03) : cs.outlineVariant.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                backgroundColor: cs.primaryContainer,
                                child: user.avatar == null || user.avatar!.isEmpty
                                    ? Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: user.email != null
                                  ? Text(
                                      user.email!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : cs.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              trailing: Builder(
                                builder: (context) {
                                  if (isMember) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Thành viên',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                                        ),
                                      ),
                                    );
                                  }

                                  if (isSending) {
                                    return const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  }

                                  if (hasPendingInvite) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        'Đang chờ...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    );
                                  }

                                  // Nút Mời chưa gửi
                                  return Container(
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
                                        setState(() => _sendingMap[user.id] = true);
                                        final ok = await widget.groupCtrl.inviteMember(widget.group.id, user.id);
                                        setState(() => _sendingMap[user.id] = false);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(ok
                                                  ? 'Đã gửi lời mời tới ${user.name} thành công!'
                                                  : (widget.groupCtrl.error ?? 'Gửi lời mời thất bại.')),
                                              backgroundColor: ok ? Colors.green.shade700 : cs.error,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Mời', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
