import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onAttach,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onAttach;

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
      padding: EdgeInsets.fromLTRB(6, 8, 8, 8 + bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment plus button (replaces pin)
          if (widget.onAttach != null)
            IconButton(
              onPressed: widget.onAttach,
              icon: const Icon(
                Icons.add_circle_rounded,
                color: Color(0xFF0084FF),
                size: 26,
              ),
              tooltip: 'Đính kèm',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 4),
          // Text input (Capsule with emoji suffix)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF242526)
                    : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(20),
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
                        color: isDark ? Colors.white : const Color(0xFF050505),
                        fontSize: 15.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : const Color(0xFF8A8D91),
                          fontSize: 15.0,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  // Emoji icon inside text capsule
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () {
                        // Action for emoji picker (can be integrated later)
                      },
                      icon: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: Color(0xFF0084FF),
                        size: 23,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Morphing Send / Thumbs up Like button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: _hasText
                ? IconButton(
                    key: const ValueKey('send'),
                    onPressed: _send,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF0084FF),
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  )
                : IconButton(
                    key: const ValueKey('like'),
                    onPressed: () => widget.onSend('👍'),
                    icon: const Icon(
                      Icons.thumb_up_rounded,
                      color: Color(0xFF0084FF),
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
          ),
        ],
      ),
    );
  }
}
