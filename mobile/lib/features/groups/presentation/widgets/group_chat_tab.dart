import 'package:flutter/material.dart';
import '../../data/models/group_message_model.dart';
import '../../data/services/group_chat_service.dart';
import 'chat_bubble.dart';
import 'chat_input_bar.dart';

class GroupChatTab extends StatefulWidget {
  const GroupChatTab({
    super.key,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.onShareDocument,
  });

  final String groupId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final VoidCallback onShareDocument;

  @override
  State<GroupChatTab> createState() => _GroupChatTabState();
}

class _GroupChatTabState extends State<GroupChatTab> {
  final _chatService = GroupChatService();
  final _scrollCtrl = ScrollController();

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
    await _chatService.sendTextMessage(
      groupId: widget.groupId,
      senderId: widget.userId,
      senderName: widget.userName,
      senderAvatar: widget.userAvatar,
      text: text,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.brightness == Brightness.dark ? const Color(0xFF0A0A0A) : cs.surface,
      child: Column(
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
                    final isMe = msg.senderId == widget.userId;
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
            onShareDocument: widget.onShareDocument,
          ),
        ],
      ),
    );
  }
}
