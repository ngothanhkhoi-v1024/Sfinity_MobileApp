import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/group_message_model.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.onDelete,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;
  /// Called when the user confirms deleting this message.
  /// Only provided for messages sent by [isMe].
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    Widget bubble;
    if (message.type == MessageType.document) {
      bubble = _DocumentBubble(message: message, isMe: isMe);
    } else if (message.type == MessageType.image) {
      bubble = _ImageBubble(
        message: message,
        isMe: isMe,
        showAvatar: showAvatar,
      );
    } else if (message.type == MessageType.file) {
      bubble = _FileBubble(message: message, isMe: isMe, showAvatar: showAvatar);
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
        );
      } else {
        bubble = _TextBubble(message: message, isMe: isMe, showAvatar: showAvatar);
      }
    }

    // Wrap with long-press delete only for own messages
    if (isMe && onDelete != null) {
      return _BubbleWrapper(
        onDelete: onDelete!,
        child: bubble,
      );
    }
    return bubble;
  }
}

// ─── Bubble Wrapper (long-press delete) ─────────────────────────────────────

class _BubbleWrapper extends StatelessWidget {
  const _BubbleWrapper({required this.onDelete, required this.child});
  final VoidCallback onDelete;
  final Widget child;

  void _showMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Xóa tin nhắn?'),
                    content: const Text(
                        'Tin nhắn này sẽ bị xóa vĩnh viễn với tất cả thành viên trong nhóm.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDelete();
                        },
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
            ),
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

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            _SenderAvatar(name: message.senderName, avatar: message.senderAvatar),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? const Color(0xFF00D2FF) : cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [
                              cs.primary,
                              cs.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            width: 0.8,
                          ),
                  ),
                  child: Text(
                    message.text ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe
                          ? Colors.white
                          : (isDark ? Colors.white.withValues(alpha: 0.95) : cs.onSurface),
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    isMe
                        ? '${_formatTime(message.createdAt)} • Đã xem'
                        : _formatTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DocumentBubble extends StatelessWidget {
  const _DocumentBubble({required this.message, required this.isMe});
  final GroupMessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _SenderAvatar(name: message.senderName, avatar: message.senderAvatar),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.76,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    final docId = message.sharedDocumentId;
                    if (docId != null && docId.isNotEmpty) {
                      context.push('/document/$docId');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMe
                            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                            : [cs.secondaryContainer, cs.secondaryContainer.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: isMe ? Colors.white : cs.onSecondaryContainer,
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
                                isMe ? 'Bạn đã chia sẻ' : '${message.senderName} chia sẻ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: (isMe ? Colors.white : cs.onSecondaryContainer).withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                message.sharedDocumentTitle ?? 'Tài liệu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isMe ? Colors.white : cs.onSecondaryContainer,
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
                          color: (isMe ? Colors.white : cs.onSecondaryContainer).withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
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
    if (avatar != null && avatar!.isNotEmpty) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatar!));
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: cs.primaryContainer,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
      ),
    );
  }
}

// ─── Image Bubble (uploaded image) ──────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final fileUrl = message.fileUrl ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            _SenderAvatar(name: message.senderName, avatar: message.senderAvatar),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? const Color(0xFF00D2FF) : cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isMe
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (fileUrl.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: InteractiveViewer(
                              child: fileUrl.startsWith('/')
                                  ? Image.file(File(fileUrl))
                                  : Image.network(fileUrl),
                            ),
                          ),
                        );
                      }
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.65,
                        maxHeight: 260,
                      ),
                      child: fileUrl.startsWith('/')
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
                if (message.text != null && message.text!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? cs.primary.withValues(alpha: 0.85)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message.text!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMe
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : cs.onSurface),
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    isMe
                        ? '${_formatTime(message.createdAt)} • Đã xem'
                        : _formatTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── File Bubble (uploaded file/PDF/doc) ────────────────────────────────────

class _FileBubble extends StatelessWidget {
  const _FileBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

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
    final fileName = message.fileName ?? 'File';
    final fileUrl = message.fileUrl ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            _SenderAvatar(name: message.senderName, avatar: message.senderAvatar),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? const Color(0xFF00D2FF) : cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: fileUrl.isEmpty
                      ? null
                      : () async {
                          final uri = Uri.parse(fileUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.72),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? cs.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe
                            ? const Radius.circular(18)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: isMe ? 0.2 : 0.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _iconForFile(fileName),
                            color: isMe
                                ? Colors.white
                                : cs.primary,
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
                                  color: isMe
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : cs.onSurface),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (message.fileSize != null)
                                Text(
                                  _formatSize(message.fileSize),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: (isMe
                                            ? Colors.white
                                            : cs.onSurfaceVariant)
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
                          color: (isMe ? Colors.white : cs.primary)
                              .withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    isMe
                        ? '${_formatTime(message.createdAt)} • Đã xem'
                        : _formatTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ImageCardBubble extends StatelessWidget {

  const _ImageCardBubble({
    required this.imgUrl,
    required this.caption,
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  final String imgUrl;
  final String caption;
  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            _SenderAvatar(name: message.senderName, avatar: message.senderAvatar),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? const Color(0xFF00D2FF) : cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: imgUrl.isEmpty || imgUrl.startsWith('http') == false
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
                                  imgUrl,
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
                      if (caption.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Text(
                            caption,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white.withValues(alpha: 0.9) : cs.onSurface,
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    isMe
                        ? '${_formatTime(message.createdAt)} • Đã xem'
                        : _formatTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
