import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/constants/route_names.dart';
import '../../data/models/group_model.dart';
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
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(context, group),
                ];
              },
              body: TabBarView(
                children: [
                  _buildChatTab(context, group),
                  _buildMembersTab(context, group),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOwnerOrAdmin = group.isAdmin;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        if (isOwnerOrAdmin)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              onPressed: () => _showEditDialog(context, group),
            ),
          ),
        if (group.isOwner)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
              onPressed: () => _confirmDelete(context, group),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            _GroupHeaderBackground(group: group),
            // Glassmorphism Overlay
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),
            // Info Column
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: group.isPublic
                              ? cs.tertiaryContainer.withValues(alpha: 0.9)
                              : cs.errorContainer.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          group.isPublic ? 'Công khai' : 'Riêng tư',
                          style: TextStyle(
                            fontSize: 10,
                            color: group.isPublic ? cs.onTertiaryContainer : cs.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  if (group.description != null && group.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Trò chuyện'),
              Tab(text: 'Thành viên'),
            ],
            indicatorWeight: 3.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
      ),
    );
  }

  // ─── TAB 1: LIVE CHAT ──────────────────────────────────────────────────────
  Widget _buildChatTab(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface,
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

    // Simulate list of files/documents for demonstration (wow feature)
    final mockDocs = [
      {'title': 'Đề cương Ôn tập Giải tích 1.pdf', 'type': 'pdf', 'size': '2.4 MB', 'author': 'Nguyễn Văn A'},
      {'title': 'Tài liệu Tự học Flutter Cơ bản.pdf', 'type': 'pdf', 'size': '5.1 MB', 'author': 'Trần Thị B'},
      {'title': 'Source Code Project mẫu.zip', 'type': 'zip', 'size': '12.8 MB', 'author': 'Chủ nhóm'},
      {'title': 'Ghi chú kiến thức Web Design.docx', 'type': 'doc', 'size': '850 KB', 'author': 'Lê Văn C'},
    ];

    return Container(
      color: cs.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tài liệu học tập (${mockDocs.length})',
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mockDocs.length,
              itemBuilder: (ctx, i) {
                final doc = mockDocs[i];
                final isPdf = doc['type'] == 'pdf';
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
                        color: isPdf
                            ? Colors.red.shade50
                            : doc['type'] == 'zip'
                                ? Colors.amber.shade50
                                : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : doc['type'] == 'zip'
                                ? Icons.folder_zip_rounded
                                : Icons.description_rounded,
                        color: isPdf
                            ? Colors.red.shade700
                            : doc['type'] == 'zip'
                                ? Colors.amber.shade800
                                : Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      doc['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${doc['size']} • Chia sẻ bởi ${doc['author']}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bắt đầu tải tài liệu về thiết bị...')),
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

  // ─── TAB 3: STUDY GOALS & LEADERBOARD ──────────────────────────────────────
  Widget _buildGoalsTab(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Leaderboard entries with contribution score (hours studied)
    final leaderboard = [
      {'name': 'Nguyễn Văn A', 'hours': '18.5h', 'rank': 1, 'avatar': null},
      {'name': 'Trần Thị B', 'hours': '14.2h', 'rank': 2, 'avatar': null},
      {'name': 'Lê Văn C', 'hours': '10.0h', 'rank': 3, 'avatar': null},
      {'name': 'Chủ nhóm', 'hours': '8.5h', 'rank': 4, 'avatar': null},
    ];

    return Container(
      color: cs.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Study goal card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.primaryContainer.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.emoji_events_rounded, color: cs.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mục tiêu chung tuần này',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tổng thời gian tự học nhóm đạt 50 giờ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến trình: 51.2h / 50h',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '102%',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.1),
                      color: cs.primary,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🎉 Tuyệt vời! Nhóm đã hoàn thành xuất sắc mục tiêu tuần này!',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Leaderboard Title
            Text(
              '🏆 Bảng xếp hạng đóng góp tuần',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboard.length,
              itemBuilder: (ctx, i) {
                final item = leaderboard[i];
                final rank = item['rank'] as int;

                return Card(
                  elevation: 0,
                  color: rank <= 3 ? cs.surfaceContainerHighest.withValues(alpha: 0.3) : cs.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: rank <= 3 ? cs.primary.withValues(alpha: 0.2) : cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: rank == 1
                              ? const Icon(Icons.workspace_premium_rounded, color: Colors.amber)
                              : rank == 2
                                  ? const Icon(Icons.workspace_premium_rounded, color: Colors.grey)
                                  : rank == 3
                                      ? const Icon(Icons.workspace_premium_rounded, color: Colors.brown)
                                      : Text('#$rank', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.person, size: 20),
                        ),
                      ],
                    ),
                    title: Text(
                      item['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item['hours'] as String,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 4: MEMBER MANAGEMENT ──────────────────────────────────────────────
  Widget _buildMembersTab(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOwnerOrAdmin = group.isAdmin;

    return Container(
      color: cs.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thành viên nhóm (${group.members.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isOwnerOrAdmin)
                  FilledButton.icon(
                    onPressed: () => _showAddMemberDialog(context, group),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Mời thành viên'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: group.members.length,
              itemBuilder: (ctx, i) {
                final member = group.members[i];
                return _MemberTile(
                  member: member,
                  myUid: _myUid,
                  isGroupAdmin: isOwnerOrAdmin,
                  isOwner: group.isOwner,
                  onRemove: group.isAdmin
                      ? () async {
                          final ok = await _groupCtrl.removeMember(group.id, member.user.id);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_groupCtrl.error ?? 'Lỗi'),
                                backgroundColor: cs.error,
                              ),
                            );
                          }
                        }
                      : null,
                );
              },
            ),
          ),
          if (!group.isOwner)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLeave(context, group),
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Rời khỏi nhóm này'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── DIALOGS & HELPER METHODS ──────────────────────────────────────────────

  Future<void> _showAddMemberDialog(BuildContext context, GroupModel group) async {
    final friends = _friendCtrl.friends;
    final existingIds = group.members.map((m) => m.user.id).toSet();
    final available = friends.where((f) => !existingIds.contains(f.user.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tất cả bạn bè đã ở trong nhóm học tập')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mời bạn bè vào nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (_, i) {
              final friend = available[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.user.avatar != null ? NetworkImage(friend.user.avatar!) : null,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: friend.user.avatar == null
                      ? Text(friend.user.name.isNotEmpty ? friend.user.name[0].toUpperCase() : '?')
                      : null,
                ),
                title: Text(friend.user.name),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _groupCtrl.addMember(group.id, friend.user.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Đã thêm ${friend.user.name}' : (_groupCtrl.error ?? 'Lỗi')),
                      backgroundColor: ok ? null : Colors.red,
                    ));
                  }
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }

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

// ─── Group Header Background ──────────────────────────────────────────────────
class _GroupHeaderBackground extends StatelessWidget {
  const _GroupHeaderBackground({required this.group});
  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    if (group.avatarUrl != null && group.avatarUrl!.isNotEmpty) {
      return Image.network(group.avatarUrl!, fit: BoxFit.cover);
    }
    final colors = _gradientForName(group.name);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  List<Color> _gradientForName(String name) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFEC4899), const Color(0xFFF97316)],
      [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % palettes.length : 0;
    return palettes[idx];
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
  final _idCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chia sẻ tài liệu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _idCtrl,
            decoration: const InputDecoration(
              labelText: 'ID tài liệu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Tên tài liệu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.picture_as_pdf_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                if (_idCtrl.text.trim().isEmpty || _titleCtrl.text.trim().isEmpty) return;
                await widget.onShare(_idCtrl.text.trim(), _titleCtrl.text.trim());
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Chia sẻ vào nhóm'),
            ),
          ),
        ],
      ),
    );
  }
}
