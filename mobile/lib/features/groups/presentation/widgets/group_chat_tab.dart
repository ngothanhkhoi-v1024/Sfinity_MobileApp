import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sfinity/app.dart';
import 'package:sfinity/features/places/data/models/place_model.dart';
import 'place_picker_sheet.dart';
import '../../../../core/i18n/app_text.dart';
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
  late Stream<List<GroupMessageModel>> _messagesStream;

  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;
  bool _showScrollToBottomBtn = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_scrollListener);
    _messagesStream = _chatService.messagesStream(widget.groupId);
  }

  @override
  void didUpdateWidget(covariant GroupChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      setState(() {
        _messagesStream = _chatService.messagesStream(widget.groupId);
      });
    }
  }

  void _scrollListener() {
    if (_scrollCtrl.hasClients) {
      final show = _scrollCtrl.offset > 400;
      if (show != _showScrollToBottomBtn) {
        setState(() {
          _showScrollToBottomBtn = show;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_scrollListener);
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
      onShareLocation: _shareLocation,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = context.l10n;
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
            content: Text('${l10n.shareDocument} $e'),
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
    final l10n = context.l10n;
    try {
      final result = await FilePicker.pickFiles(
          type: FileType.any, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final pf = result.files.first;
      if (pf.path == null) return;

      // Giới hạn tệp không lớn hơn 200MB (200 * 1024 * 1024 bytes)
      const int maxSizeBytes = 200 * 1024 * 1024;
      if (pf.size > maxSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.shareDocument),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

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
            content: Text(l10n.shareDocument),
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

  Future<void> _shareLocation() async {
    final l10n = context.l10n;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final currentUserId = widget.userId;
      // Load my places and public places
      final myPlaces = await SfinityApp.placeRepository.listPlaces(
        PlaceListQuery(authorId: currentUserId),
      );
      final publicPlaces = await SfinityApp.placeRepository.listPlaces(
        PlaceListQuery(publishedOnly: true),
      );

      if (mounted) Navigator.pop(context); // Dismiss loading

      if (!mounted) return;
      final selectedPlace = await showModalBottomSheet<PlaceModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return PlacePickerSheet(
            myPlaces: myPlaces,
            publicPlaces: publicPlaces,
          );
        },
      );

      if (selectedPlace != null) {
        await _chatService.sendLocationMessage(
          groupId: widget.groupId,
          senderId: widget.userId,
          senderName: widget.userName,
          senderAvatar: widget.userAvatar,
          latitude: selectedPlace.latitude ?? 0.0,
          longitude: selectedPlace.longitude ?? 0.0,
          address: selectedPlace.title,
          placeId: selectedPlace.id,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupChatError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      color: cs.brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : cs.surface,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<GroupMessageModel>>(
                  stream: _messagesStream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text(l10n.groupChatError(snap.error.toString())));
                    }
                    final rawMessages = snap.data ?? [];
                    final messages = rawMessages.where((msg) {
                      if (msg.type == MessageType.text && msg.text != null) {
                        final txt = msg.text!.toLowerCase();
                        if (txt.startsWith('đã gửi file:') || txt.startsWith('đã gửi ảnh:')) {
                          final isImg = txt.endsWith('.png') ||
                              txt.endsWith('.jpg') ||
                              txt.endsWith('.jpeg') ||
                              txt.endsWith('.gif') ||
                              txt.endsWith('.webp') ||
                              txt.endsWith('.bmp');
                          if (isImg) return false;
                        }
                      }
                      return true;
                    }).toList();
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
                            Text(l10n.noMessages,
                                style: TextStyle(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text(
                              l10n.noMessagesGroup,
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

                        bool isConsecutive(GroupMessageModel current, GroupMessageModel other) {
                          if (current.senderId != other.senderId) return false;
                          final diff = current.createdAt.difference(other.createdAt).abs();
                          if (diff.inMinutes > 5) return false;

                          final d1 = current.createdAt;
                          final d2 = other.createdAt;
                          return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
                        }

                        final showName = i == messages.length - 1 ||
                            !isConsecutive(msg, messages[i + 1]);

                        final showAvatar = i == 0 ||
                            !isConsecutive(msg, messages[i - 1]);

                        return ChatBubble(
                          message: msg,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          showName: showName,
                          currentUserId: widget.userId,
                          groupId: widget.groupId,
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
                if (_showScrollToBottomBtn)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton.small(
                        onPressed: _scrollToBottom,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.arrow_downward_rounded),
                      ),
                    ),
                  ),
              ],
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
