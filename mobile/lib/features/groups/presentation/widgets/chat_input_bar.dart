import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onShareDocument,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onShareDocument;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isDark = cs.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 12, 12, 12 + bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : cs.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : cs.outlineVariant.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Share document button (Attachment pin)
          if (widget.onShareDocument != null)
            IconButton(
              onPressed: widget.onShareDocument,
              icon: Icon(
                Icons.attach_file_rounded,
                color: isDark ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant,
                size: 24,
              ),
              tooltip: 'Chia sẻ tài liệu',
              padding: const EdgeInsets.all(6),
            ),
          // Text input (Capsule with emoji suffix)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 14.5,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  // Emoji icon
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () {
                        // Action for emoji picker
                      },
                      icon: Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: isDark ? Colors.white.withValues(alpha: 0.45) : cs.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button (Gradient circle)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: _hasText
                  ? LinearGradient(
                      colors: [cs.primary, cs.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _hasText
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE5E7EB)),
              shape: BoxShape.circle,
              boxShadow: _hasText
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: _hasText ? _send : null,
              icon: Icon(
                Icons.send_rounded,
                color: _hasText
                    ? Colors.white
                    : (isDark ? Colors.white.withValues(alpha: 0.25) : cs.onSurfaceVariant.withValues(alpha: 0.3)),
                size: 20,
              ),
              padding: const EdgeInsets.all(11),
            ),
          ),
        ],
      ),
    );
  }
}
