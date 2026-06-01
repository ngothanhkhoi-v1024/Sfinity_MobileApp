import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/group_message_model.dart';
import '../../data/services/group_chat_service.dart';
import 'attachment_menu.dart';
import 'chat_bubble.dart';
import 'chat_input_bar.dart';

class GroupChatTab extends StatefulWidget {
  const GroupChatTab({
    super.key,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  final String groupId;
  final String userId;
  final String userName;
  final String? userAvatar;

  @override
  State<GroupChatTab> createState() => _GroupChatTabState();
}

class _GroupChatTabState extends State<GroupChatTab> {
  final _chatService = GroupChatService();
  final _scrollCtrl = ScrollController();

  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;

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

  void _showAttachmentMenu() {
    AttachmentMenu.show(
      context: context,
      onPickImage: _pickImage,
      onPickFile: _pickFile,
      onShareDoc: _showShareDocumentSheet,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;

      setState(() {
        _uploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = picked.name;
      });

      await _chatService.sendImageMessage(
        groupId: widget.groupId,
        senderId: widget.userId,
        senderName: widget.userName,
        senderAvatar: widget.userAvatar,
        imageFile: File(picked.path),
        fileName: picked.name,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi ảnh thất bại: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0.0;
          _uploadingFileName = null;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
          type: FileType.any, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final pf = result.files.first;
      if (pf.path == null) return;

      setState(() {
        _uploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = pf.name;
      });

      await _chatService.sendFileMessage(
        groupId: widget.groupId,
        senderId: widget.userId,
        senderName: widget.userName,
        senderAvatar: widget.userAvatar,
        file: File(pf.path!),
        fileName: pf.name,
        fileSize: pf.size,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi file thất bại: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0.0;
          _uploadingFileName = null;
        });
      }
    }
  }

  Future<void> _showShareDocumentSheet() async {
    AttachmentMenu.showShareDocSheet(
      context: context,
      chatService: _chatService,
      groupId: widget.groupId,
      senderId: widget.userId,
      senderName: widget.userName,
      senderAvatar: widget.userAvatar,
      onDone: _scrollToBottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : cs.surface,
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
                        Text('Chưa có tin nhắn nào',
                            style: TextStyle(color: cs.onSurfaceVariant)),
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
                      onDelete: isMe
                          ? () => _chatService.deleteMessage(
                                groupId: widget.groupId,
                                messageId: msg.id,
                              )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          if (_uploading)
            UploadProgressBar(
              progress: _uploadProgress,
              fileName: _uploadingFileName,
            ),
          ChatInputBar(
            onSend: _sendMessage,
            onAttach: _showAttachmentMenu,
          ),
        ],
      ),
    );
  }
}
