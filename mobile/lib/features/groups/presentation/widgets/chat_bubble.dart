import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/group_message_model.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
  });

  final GroupMessageModel message;
  final bool isMe;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.document) {
      return _DocumentBubble(message: message, isMe: isMe);
    }
    
    final text = message.text ?? '';
    if (message.type == MessageType.text && text.startsWith('[img]')) {
      final content = text.substring(5);
      final parts = content.split('|');
      final imgUrl = parts[0];
      final caption = parts.length > 1 ? parts[1] : '';
      return _ImageCardBubble(
        imgUrl: imgUrl,
        caption: caption,
        message: message,
        isMe: isMe,
        showAvatar: showAvatar,
      );
    }

    return _TextBubble(message: message, isMe: isMe, showAvatar: showAvatar);
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
