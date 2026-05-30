import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/auth/auth_state.dart';
import '../../data/models/group_message_model.dart';
import '../../data/services/group_chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key, required this.groupId, this.groupName});
  final String groupId;
  final String? groupName;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _chatService = GroupChatService();
  final _scrollCtrl = ScrollController();
  late final AuthState _auth;
  String? _userName;
  String? _userAvatar;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _auth = SfinityApp.auth;
    _userId = _auth.user?['id']?.toString();
    _userName = _auth.user?['name']?.toString() ?? 'Bạn';
    _userAvatar = _auth.user?['avatar']?.toString();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName ?? 'Chat nhóm',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              'Nhóm học tập',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GroupMessageModel>>(
              stream: _chatService.messagesStream(widget.groupId),
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
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('Chưa có tin nhắn nào', style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Hãy là người đầu tiên gửi tin!', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
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
          Text('Chia sẻ tài liệu', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
