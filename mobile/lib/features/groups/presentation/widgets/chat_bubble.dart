import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/group_message_model.dart';
import '../../data/services/group_chat_service.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.showName = true,
    required this.currentUserId,
    required this.groupId,
    this.onDelete,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;
  final String currentUserId;
  final String groupId;
  /// Called when the user confirms deleting this message.
  /// Only provided for messages sent by [isMe].
  final VoidCallback? onDelete;

  bool _isImageFile(String? fileName) {
    if (fileName == null) return false;
    final lowercase = fileName.toLowerCase();
    return lowercase.endsWith('.png') ||
        lowercase.endsWith('.jpg') ||
        lowercase.endsWith('.jpeg') ||
        lowercase.endsWith('.gif') ||
        lowercase.endsWith('.webp') ||
        lowercase.endsWith('.bmp');
  }

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _DeletedBubble(
        message: message,
        isMe: isMe,
        showAvatar: showAvatar,
        showName: showName,
      );
    }

    final isImage = message.type == MessageType.image ||
        (message.type == MessageType.file && _isImageFile(message.fileName));

    Widget bubble;
    if (message.type == MessageType.document) {
      bubble = _DocumentBubble(
        message: message,
        isMe: isMe,
        showAvatar: showAvatar,
        showName: showName,
      );
    } else if (isImage) {
      bubble = _ImageBubble(
        message: message,
        isMe: isMe,
        showAvatar: showAvatar,
        showName: showName,
      );
    } else if (message.type == MessageType.file) {
      bubble = _FileBubble(
        message: message,
        isMe: isMe,
        showAvatar: showAvatar,
        showName: showName,
      );
    } else {
      final text = message.text ?? '';
      if (message.type == MessageType.text && text.startsWith('[img]')) {
        final content = text.substring(5);
        final parts = content.split('|');
        final imgUrl = parts[0];
        final caption = parts.length > 1 ? parts[1] : '';
        bubble = _ImageCardBubble(
          imgUrl: imgUrl,
          caption: caption,
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          showName: showName,
        );
      } else {
        bubble = _TextBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          showName: showName,
        );
      }
    }

    return _BubbleWrapper(
      groupId: groupId,
      currentUserId: currentUserId,
      message: message,
      onDelete: isMe ? onDelete : null,
      child: bubble,
    );
  }
}

// ─── Bubble Shape Helper ─────────────────────────────────────────────────────

BorderRadius _getBubbleRadius({
  required bool isMe,
  required bool isFirst,
  required bool isLast,
}) {
  const double radiusMax = 18.0;
  const double radiusMin = 4.0;

  if (isMe) {
    return BorderRadius.only(
      topLeft: const Radius.circular(radiusMax),
      topRight: Radius.circular(isFirst ? radiusMax : radiusMin),
      bottomLeft: const Radius.circular(radiusMax),
      bottomRight: Radius.circular(isLast ? radiusMax : radiusMin),
    );
  } else {
    return BorderRadius.only(
      topLeft: Radius.circular(isFirst ? radiusMax : radiusMin),
      topRight: const Radius.circular(radiusMax),
      bottomLeft: Radius.circular(isLast ? radiusMax : radiusMin),
      bottomRight: const Radius.circular(radiusMax),
    );
  }
}

// ─── Date Formatter Helper ───────────────────────────────────────────────────

String _formatMessageTime(DateTime dt, bool showFull) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final timeStr = '$h:$m';
  
  if (!showFull) {
    return timeStr;
  }
  
  // Check if same day as today
  final now = DateTime.now();
  final isSameDay = now.year == dt.year && now.month == dt.month && now.day == dt.day;
  if (isSameDay) {
    return timeStr;
  }
  
  // Different day: show full date and time
  final dayStr = dt.day.toString().padLeft(2, '0');
  final monthStr = dt.month.toString().padLeft(2, '0');
  final yearStr = dt.year;
  return '$timeStr - $dayStr/$monthStr/$yearStr';
}

// ─── Bubble Wrapper (long-press delete) ─────────────────────────────────────

class _BubbleWrapper extends StatelessWidget {
  const _BubbleWrapper({
    required this.groupId,
    required this.currentUserId,
    required this.message,
    this.onDelete,
    required this.child,
  });

  final String groupId;
  final String currentUserId;
  final GroupMessageModel message;
  final VoidCallback? onDelete;
  final Widget child;

  void _showMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final chatService = GroupChatService();

    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    final userReaction = message.reactions[currentUserId];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Thả cảm xúc',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : cs.outlineVariant.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: emojis.map((emoji) {
                  final isSelected = userReaction == emoji;
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await chatService.reactToMessage(
                        groupId: groupId,
                        messageId: message.id,
                        userId: currentUserId,
                        emoji: isSelected ? null : emoji,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: cs.primary, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 22),
                ),
                title: Text(
                  'Xóa tin nhắn',
                  style: TextStyle(
                    color: cs.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Tin nhắn sẽ bị xóa với tất cả mọi người',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Confirm dialog
                  showDialog(
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
                                'Xóa tin nhắn?',
                                style: dialogTheme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: dialogIsDark ? Colors.white : const Color(0xFF050505),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tin nhắn này sẽ bị xóa vĩnh viễn với tất cả thành viên trong nhóm.',
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
                                        onPressed: () => Navigator.pop(ctx),
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
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          onDelete!();
                                        },
                                        child: const Text(
                                          'Xóa',
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
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: child,
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 2,
        bottom: showAvatar ? 10 : 2,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 44, right: 8),
              child: Text(
                message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && showAvatar) ...[
                _SenderAvatar(name: message.senderName, avatar: message.senderAvatar),
                const SizedBox(width: 8),
              ] else if (!isMe) ...[
                const SizedBox(width: 36),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: _getBubbleRadius(
                      isMe: isMe,
                      isFirst: showName,
                      isLast: showAvatar,
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    'Tin nhắn đã bị thu hồi',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontStyle: FontStyle.italic,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextBubble extends StatefulWidget {
  const _TextBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;

  @override
  State<_TextBubble> createState() => _TextBubbleState();
}

class _TextBubbleState extends State<_TextBubble> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 2,
        bottom: widget.showAvatar ? 10 : 2,
      ),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 44, right: 8),
              child: Text(
                widget.message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe && widget.showAvatar) ...[
                _SenderAvatar(name: widget.message.senderName, avatar: widget.message.senderAvatar),
                const SizedBox(width: 8),
              ] else if (!widget.isMe) ...[
                const SizedBox(width: 36),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: () => setState(() => _showTime = !_showTime),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.isMe
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF0084FF),
                                Color(0xFF00C6FF),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            )
                          : null,
                      color: widget.isMe
                          ? null
                          : (isDark
                              ? const Color(0xFF242526)
                              : const Color(0xFFF0F2F5)),
                      borderRadius: _getBubbleRadius(
                        isMe: widget.isMe,
                        isFirst: widget.showName,
                        isLast: widget.showAvatar,
                      ),
                      border: widget.isMe
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              width: 0.8,
                            ),
                    ),
                    child: Text(
                      widget.message.text ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isMe
                            ? Colors.white
                            : (isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF050505)),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.isMe) const SizedBox(width: 4),
            ],
          ),
          if (widget.message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: _ReactionBadges(reactions: widget.message.reactions, isMe: widget.isMe),
            ),
          if (widget.showAvatar || _showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: Text(
                widget.isMe
                    ? '${_formatMessageTime(widget.message.createdAt, _showTime)} • Đã xem'
                    : _formatMessageTime(widget.message.createdAt, _showTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF65676B) : const Color(0xFF8A8D91),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentBubble extends StatefulWidget {
  const _DocumentBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
  });
  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;

  @override
  State<_DocumentBubble> createState() => _DocumentBubbleState();
}

class _DocumentBubbleState extends State<_DocumentBubble> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 2,
        bottom: widget.showAvatar ? 10 : 2,
      ),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 44, right: 8),
              child: Text(
                widget.message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe && widget.showAvatar) ...[
                _SenderAvatar(name: widget.message.senderName, avatar: widget.message.senderAvatar),
                const SizedBox(width: 8),
              ] else if (!widget.isMe) ...[
                const SizedBox(width: 36),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: _getBubbleRadius(
                        isMe: widget.isMe,
                        isFirst: widget.showName,
                        isLast: widget.showAvatar,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        setState(() => _showTime = !_showTime);
                        final docId = widget.message.sharedDocumentId;
                        if (docId != null && docId.isNotEmpty) {
                          context.push('/document/$docId');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: widget.isMe
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: widget.isMe
                              ? null
                              : (isDark
                                  ? const Color(0xFF242526)
                                  : const Color(0xFFF0F2F5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: widget.isMe ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.picture_as_pdf_rounded,
                                color: widget.isMe
                                    ? Colors.white
                                    : (isDark ? Colors.white.withValues(alpha: 0.9) : cs.primary),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.isMe ? 'Bạn đã chia sẻ' : '${widget.message.senderName} chia sẻ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: (widget.isMe
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white.withValues(alpha: 0.6)
                                                  : cs.onSurfaceVariant))
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.message.sharedDocumentTitle ?? 'Tài liệu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: widget.isMe
                                          ? Colors.white
                                          : (isDark ? Colors.white.withValues(alpha: 0.9) : cs.onSurface),
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: (widget.isMe
                                      ? Colors.white
                                      : (isDark ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant))
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.isMe) const SizedBox(width: 4),
            ],
          ),
          if (widget.message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: _ReactionBadges(reactions: widget.message.reactions, isMe: widget.isMe),
            ),
          if (widget.showAvatar || _showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: Text(
                widget.isMe
                    ? '${_formatMessageTime(widget.message.createdAt, _showTime)} • Đã xem'
                    : _formatMessageTime(widget.message.createdAt, _showTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF65676B) : const Color(0xFF8A8D91),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.name, this.avatar});
  final String name;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    if (avatar != null && avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(avatar!),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
        ),
      ),
    );
  }
}

class _ReactionBadges extends StatelessWidget {
  const _ReactionBadges({required this.reactions, required this.isMe});
  final Map<String, String> reactions;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // Group reactions by emoji to count them
    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    // Sort emojis by count descending
    final sortedEmojis = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: sortedEmojis.map((emoji) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 13.5),
                ),
              );
            }).toList(),
          ),
          if (reactions.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              '${reactions.length}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Image Bubble (uploaded image) ──────────────────────────────────────────

class _ImageBubble extends StatefulWidget {
  const _ImageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;

  @override
  State<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<_ImageBubble> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final fileUrl = widget.message.fileUrl ?? '';
    final isLocal = fileUrl.isNotEmpty && !fileUrl.startsWith('http');

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 2,
        bottom: widget.showAvatar ? 10 : 2,
      ),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 44, right: 8),
              child: Text(
                widget.message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe && widget.showAvatar) ...[
                _SenderAvatar(name: widget.message.senderName, avatar: widget.message.senderAvatar),
                const SizedBox(width: 8),
              ] else if (!widget.isMe) ...[
                const SizedBox(width: 36),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: () => setState(() => _showTime = !_showTime),
                  child: Column(
                    crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: _getBubbleRadius(
                          isMe: widget.isMe,
                          isFirst: widget.showName,
                          isLast: widget.showAvatar,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (fileUrl.isNotEmpty) {
                              _showFullscreenImage(context, fileUrl, isLocal);
                            }
                          },
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.65,
                              maxHeight: 260,
                            ),
                            child: isLocal
                                ? Image.file(
                                    File(fileUrl),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Image.network(
                                    fileUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        width: 200,
                                        height: 160,
                                        color: isDark
                                            ? Colors.white12
                                            : Colors.black12,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: progress.expectedTotalBytes != null
                                                ? progress.cumulativeBytesLoaded /
                                                    progress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, err, stack) => Container(
                                      width: 200,
                                      height: 160,
                                      color: isDark ? Colors.white12 : Colors.black12,
                                      child: const Icon(Icons.broken_image_rounded),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (widget.message.text != null &&
                          widget.message.text!.isNotEmpty &&
                          !(widget.message.text!.toLowerCase().startsWith('đã gửi file:') ||
                            widget.message.text!.toLowerCase().startsWith('đã gửi ảnh:')))
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: widget.isMe
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF0084FF),
                                      Color(0xFF00C6FF),
                                    ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  )
                                : null,
                            color: widget.isMe
                                ? null
                                : (isDark
                                    ? const Color(0xFF242526)
                                    : const Color(0xFFF0F2F5)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            widget.message.text!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: widget.isMe
                                  ? Colors.white
                                  : (isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF050505)),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.isMe) const SizedBox(width: 4),
            ],
          ),
          if (widget.message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: _ReactionBadges(reactions: widget.message.reactions, isMe: widget.isMe),
            ),
          if (widget.showAvatar || _showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: Text(
                widget.isMe
                    ? '${_formatMessageTime(widget.message.createdAt, _showTime)} • Đã xem'
                    : _formatMessageTime(widget.message.createdAt, _showTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF65676B) : const Color(0xFF8A8D91),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── File Bubble (uploaded file/PDF/doc) ────────────────────────────────────

class _FileBubble extends StatefulWidget {
  const _FileBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;

  @override
  State<_FileBubble> createState() => _FileBubbleState();
}

class _FileBubbleState extends State<_FileBubble> {
  bool _showTime = false;

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconForFile(String? name) {
    final ext = name?.split('.').lastOrNull?.toLowerCase() ?? '';
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'xls' || 'xlsx' => Icons.table_chart_rounded,
      'ppt' || 'pptx' => Icons.slideshow_rounded,
      'zip' || 'rar' => Icons.folder_zip_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final fileName = widget.message.fileName ?? 'File';
    final fileUrl = widget.message.fileUrl ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 2,
        bottom: widget.showAvatar ? 10 : 2,
      ),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 44, right: 8),
              child: Text(
                widget.message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe && widget.showAvatar) ...[
                _SenderAvatar(name: widget.message.senderName, avatar: widget.message.senderAvatar),
                const SizedBox(width: 8),
              ] else if (!widget.isMe) ...[
                const SizedBox(width: 36),
              ],
              Flexible(
                child: InkWell(
                  borderRadius: _getBubbleRadius(
                    isMe: widget.isMe,
                    isFirst: widget.showName,
                    isLast: widget.showAvatar,
                  ),
                  onTap: () async {
                    setState(() => _showTime = !_showTime);
                    if (fileUrl.isNotEmpty) {
                      final uri = Uri.parse(fileUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (_) {
                        try {
                          await launchUrl(uri, mode: LaunchMode.platformDefault);
                        } catch (_) {}
                      }
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.72),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: widget.isMe
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF0084FF),
                                Color(0xFF00C6FF),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            )
                          : null,
                      color: widget.isMe
                          ? null
                          : (isDark
                              ? const Color(0xFF242526)
                              : const Color(0xFFF0F2F5)),
                      borderRadius: _getBubbleRadius(
                        isMe: widget.isMe,
                        isFirst: widget.showName,
                        isLast: widget.showAvatar,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: widget.isMe ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _iconForFile(fileName),
                            color: widget.isMe
                                ? Colors.white
                                : (isDark ? Colors.white.withValues(alpha: 0.9) : cs.primary),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: widget.isMe
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.95)
                                          : const Color(0xFF050505)),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.message.fileSize != null)
                                Text(
                                  _formatSize(widget.message.fileSize),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: (widget.isMe
                                            ? Colors.white.withValues(alpha: 0.7)
                                            : (isDark ? Colors.white60 : cs.onSurfaceVariant))
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.download_rounded,
                          size: 18,
                          color: (widget.isMe
                                  ? Colors.white
                                  : (isDark ? Colors.white.withValues(alpha: 0.7) : cs.primary))
                              .withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.isMe) const SizedBox(width: 4),
            ],
          ),
          if (widget.message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: _ReactionBadges(reactions: widget.message.reactions, isMe: widget.isMe),
            ),
          if (widget.showAvatar || _showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: Text(
                widget.isMe
                    ? '${_formatMessageTime(widget.message.createdAt, _showTime)} • Đã xem'
                    : _formatMessageTime(widget.message.createdAt, _showTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF65676B) : const Color(0xFF8A8D91),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageCardBubble extends StatefulWidget {
  const _ImageCardBubble({
    required this.imgUrl,
    required this.caption,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
  });

  final String imgUrl;
  final String caption;
  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;

  @override
  State<_ImageCardBubble> createState() => _ImageCardBubbleState();
}

class _ImageCardBubbleState extends State<_ImageCardBubble> {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 2,
        bottom: widget.showAvatar ? 10 : 2,
      ),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 44, right: 8),
              child: Text(
                widget.message.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe && widget.showAvatar) ...[
                _SenderAvatar(name: widget.message.senderName, avatar: widget.message.senderAvatar),
                const SizedBox(width: 8),
              ] else if (!widget.isMe) ...[
                const SizedBox(width: 36),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: () => setState(() => _showTime = !_showTime),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF242526)
                          : const Color(0xFFF0F2F5),
                      borderRadius: _getBubbleRadius(
                        isMe: widget.isMe,
                        isFirst: widget.showName,
                        isLast: widget.showAvatar,
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (widget.imgUrl.isNotEmpty) {
                              _showFullscreenImage(context, widget.imgUrl, false);
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(widget.showName ? 17 : 3),
                              bottom: Radius.circular(widget.showAvatar ? 17 : 3),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: widget.imgUrl.isEmpty || widget.imgUrl.startsWith('http') == false
                                  ? Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFE53935), Color(0xFFFF8A65)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: CustomPaint(
                                        painter: _WavePainter(),
                                      ),
                                    )
                                  : Image.network(
                                      widget.imgUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFE53935), Color(0xFFFF8A65)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: CustomPaint(
                                            painter: _WavePainter(),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                        if (widget.caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Text(
                              widget.caption,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF050505),
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.isMe) const SizedBox(width: 4),
            ],
          ),
          if (widget.message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: _ReactionBadges(reactions: widget.message.reactions, isMe: widget.isMe),
            ),
          if (widget.showAvatar || _showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: widget.isMe ? 8 : 44,
                right: widget.isMe ? 12 : 8,
              ),
              child: Text(
                widget.isMe
                    ? '${_formatMessageTime(widget.message.createdAt, _showTime)} • Đã xem'
                    : _formatMessageTime(widget.message.createdAt, _showTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? const Color(0xFF65676B) : const Color(0xFF8A8D91),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final waveCount = 6;
    for (var i = 0; i < waveCount; i++) {
      final progress = i / (waveCount - 1);
      paint.color = Colors.white.withValues(alpha: 0.05 + (progress * 0.12));
      paint.strokeWidth = 1.2 + (progress * 1.8);

      final path = Path();
      final yOffset = size.height * (0.35 + (progress * 0.35));
      path.moveTo(0, yOffset);

      path.cubicTo(
        size.width * 0.25,
        yOffset - 25 - (i * 3),
        size.width * 0.5,
        yOffset + 35 + (i * 2),
        size.width * 0.75,
        yOffset - 15 - (i * 2),
      );

      path.quadraticBezierTo(
        size.width * 0.88,
        yOffset - 5,
        size.width,
        yOffset + 10,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showFullscreenImage(BuildContext context, String url, bool isLocal) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (context, _, __) => GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: InteractiveViewer(
              maxScale: 4.0,
              child: isLocal
                  ? Image.file(
                      File(url),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
