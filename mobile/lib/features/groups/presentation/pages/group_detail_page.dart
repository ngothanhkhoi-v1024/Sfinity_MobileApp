import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/auth/auth_state.dart';
import '../../data/models/group_model.dart';
import '../../data/services/group_chat_service.dart';
import '../controllers/group_controller.dart';
import '../../../friendships/presentation/controllers/friendship_controller.dart';
import '../widgets/attachment_menu.dart';
import '../widgets/group_chat_tab.dart';
import '../widgets/group_files_tab.dart';
import '../widgets/group_members_tab.dart';
import '../widgets/invite_member_sheet.dart';

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
                  ),
                  GroupFilesTab(
                    groupId: group.id,
                    members: group.members,
                    onShareDocument: () => AttachmentMenu.showShareDocSheet(
                      context: context,
                      chatService: _chatService,
                      groupId: group.id,
                      senderId: _myUid,
                      senderName: _userName ?? 'Bạn',
                      senderAvatar: _userAvatar,
                    ),
                  ),
                  GroupMembersTab(
                    group: group,
                    myUid: _myUid,
                    groupCtrl: _groupCtrl,
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
                  : const Color(0xFF0084FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: isDark ? Colors.white : const Color(0xFF0084FF),
            unselectedLabelColor: isDark ? Colors.white.withValues(alpha: 0.5) : cs.onSurfaceVariant.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
            tabs: const [
              Tab(text: 'Trò chuyện'),
              Tab(text: 'Kho lưu trữ'),
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
    final isGroupOwner = group.isOwner || group.creatorId == _userId || group.members.any((m) => m.user.id == _userId && m.role == 'OWNER');

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
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
                    Navigator.pop(sheetCtx);
                    _showEditDialog(context, group);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_add_outlined, color: isDark ? Colors.white.withValues(alpha: 0.7) : cs.onSurfaceVariant),
                  title: const Text('Thêm thành viên', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showInviteMemberSheet(context, group);
                  },
                ),
              ],
              if (isGroupOwner)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                  title: Text('Giải tán nhóm', style: TextStyle(color: cs.error, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _confirmDelete(context, group);
                  },
                ),
              if (!isGroupOwner || (isGroupOwner && group.members.length > 1))
                ListTile(
                  leading: Icon(Icons.exit_to_app_rounded, color: cs.error),
                  title: Text('Rời khỏi nhóm', style: TextStyle(color: cs.error, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
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
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;
          final isDark = cs.brightness == Brightness.dark;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161616) : cs.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : cs.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chỉnh sửa nhóm',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : cs.onSurface,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),

                  // Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tên nhóm học tập',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          style: TextStyle(color: isDark ? Colors.white : cs.onSurface, fontSize: 14.5),
                          decoration: InputDecoration(
                            hintText: 'Nhập tên nhóm...',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF242526) : cs.surfaceContainerHigh.withValues(alpha: 0.4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: cs.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Mô tả nhóm',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          style: TextStyle(color: isDark ? Colors.white : cs.onSurface, fontSize: 14.5),
                          decoration: InputDecoration(
                            hintText: 'Nhập mô tả ngắn cho nhóm...',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF242526) : cs.surfaceContainerHigh.withValues(alpha: 0.4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: cs.primary, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isDark ? const Color(0xFF1E1E1E) : cs.surfaceContainerHigh.withValues(alpha: 0.3),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Nhóm công khai',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : cs.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              isPublic ? 'Mọi người có thể tìm và tham gia' : 'Chỉ những ai được mời mới có thể tham gia',
                              style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                            ),
                            value: isPublic,
                            activeColor: cs.primary,
                            onChanged: (v) => setSt(() => isPublic = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: cs.outline),
                            ),
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.outline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                await _groupCtrl.updateGroup(
                                  group.id,
                                  name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  isPublic: isPublic,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Lưu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showNewOwnerSelectDialog(BuildContext context, GroupModel group) async {
    final otherMembers = group.members.where((m) => m.user.id != _myUid).toList();
    if (otherMembers.isEmpty) return null;

    GroupMemberModel? selectedMember = otherMembers.first;
    String searchPattern = '';

    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final dialogTheme = Theme.of(ctx);
          final dialogIsDark = dialogTheme.brightness == Brightness.dark;
          final cs = dialogTheme.colorScheme;

          final filteredMembers = otherMembers
              .where((m) => m.user.name.toLowerCase().contains(searchPattern.toLowerCase()))
              .toList();

          return Dialog(
            backgroundColor: dialogIsDark ? const Color(0xFF242526) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chọn Trưởng nhóm mới',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trước khi rời nhóm, bạn bắt buộc phải chuyển quyền Trưởng nhóm cho một thành viên khác.',
                    style: dialogTheme.textTheme.bodyMedium?.copyWith(
                      color: dialogIsDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => setSt(() => searchPattern = val),
                    style: TextStyle(
                      color: dialogIsDark ? Colors.white : const Color(0xFF050505),
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm thành viên...',
                      hintStyle: TextStyle(
                        color: dialogIsDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: dialogIsDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: dialogIsDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: dialogIsDark ? Colors.white12 : Colors.grey.shade200,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: filteredMembers.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Không tìm thấy thành viên',
                                style: TextStyle(
                                  color: dialogIsDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Scrollbar(
                              thumbVisibility: true,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredMembers.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: dialogIsDark ? Colors.white12 : Colors.grey.shade100,
                                ),
                                itemBuilder: (ctx, idx) {
                                  final m = filteredMembers[idx];
                                  return InkWell(
                                    onTap: () => setSt(() => selectedMember = m),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundImage: m.user.avatar != null && m.user.avatar!.isNotEmpty
                                                ? NetworkImage(m.user.avatar!)
                                                : null,
                                            child: m.user.avatar == null || m.user.avatar!.isEmpty
                                                ? Text(
                                                    m.user.name.isNotEmpty ? m.user.name[0].toUpperCase() : '?',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              m.user.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Radio<String>(
                                            value: m.user.id,
                                            groupValue: selectedMember?.user.id,
                                            activeColor: cs.primary,
                                            onChanged: (_) => setSt(() => selectedMember = m),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none,
                              backgroundColor: dialogIsDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF0F2F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, null),
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                color: dialogIsDark ? Colors.white70 : const Color(0xFF65676B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(ctx, selectedMember?.user.id),
                            child: const Text(
                              'Xác nhận',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, GroupModel group) async {
    final isOwner = group.creatorId == _myUid || group.isOwner || group.members.any((m) => m.user.id == _myUid && m.role == 'OWNER');
    String? newOwnerId;

    if (isOwner) {
      newOwnerId = await _showNewOwnerSelectDialog(context, group);
      if (newOwnerId == null) return; // Abort if cancelled
      if (!context.mounted) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        final dialogIsDark = dialogTheme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: dialogIsDark ? const Color(0xFF242526) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Rời nhóm?',
                  style: dialogTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: dialogIsDark ? Colors.white : const Color(0xFF050505),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có chắc chắn muốn rời nhóm học tập "${group.name}"?',
                  style: dialogTheme.textTheme.bodyMedium?.copyWith(
                    color: dialogIsDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            backgroundColor: dialogIsDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF0F2F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              color: dialogIsDark ? Colors.white70 : const Color(0xFF65676B),
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Rời nhóm',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed == true) {
      final ok = await _groupCtrl.leaveGroup(group.id, newOwnerId: newOwnerId);
      if (context.mounted) {
        if (ok) {
          context.go('/?tab=3');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_groupCtrl.error ?? 'Lỗi')));
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, GroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        final dialogIsDark = dialogTheme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: dialogIsDark ? const Color(0xFF242526) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Giải tán nhóm?',
                  style: dialogTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: dialogIsDark ? Colors.white : const Color(0xFF050505),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có chắc chắn muốn xóa nhóm "${group.name}"? Tất cả lịch sử tin nhắn sẽ bị xóa vĩnh viễn.',
                  style: dialogTheme.textTheme.bodyMedium?.copyWith(
                    color: dialogIsDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            backgroundColor: dialogIsDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF0F2F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              color: dialogIsDark ? Colors.white70 : const Color(0xFF65676B),
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Giải tán',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed == true) {
      final ok = await _groupCtrl.deleteGroup(group.id);
      if (context.mounted) {
        if (ok) {
          context.go('/?tab=3');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_groupCtrl.error ?? 'Lỗi')));
        }
      }
    }
  }
}
