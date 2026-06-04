import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/group_message_model.dart';
import '../../data/models/group_model.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, this.onTap});

  final GroupModel group;
  final VoidCallback? onTap;

  Stream<GroupMessageModel?> get _latestMessageStream {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(group.id)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return GroupMessageModel.fromFirestore(snap.docs.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupMessageModel?>(
      stream: _latestMessageStream,
      builder: (context, snapshot) {
        final message = snapshot.hasError ? null : snapshot.data;
        return _GroupCardBody(
          group: group,
          message: message,
          onTap: onTap,
        );
      },
    );
  }
}

class _GroupCardBody extends StatelessWidget {
  const _GroupCardBody({
    required this.group,
    required this.message,
    required this.onTap,
  });

  final GroupModel group;
  final GroupMessageModel? message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final preview = _messagePreview(message);
    final sender = message?.senderName.trim() ?? '';
    final time = message == null ? '' : DateFormat('HH:mm').format(message!.createdAt);
    final hasPreview = preview.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : cs.outlineVariant.withValues(alpha: 0.7),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              children: [
                _GroupAvatar(group: group),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF171717),
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Text(
                              time,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.42)
                                    : cs.onSurfaceVariant.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: 18,
                        child: hasPreview
                            ? RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : cs.onSurfaceVariant,
                                    height: 1.25,
                                    letterSpacing: 0,
                                  ),
                                  children: [
                                    if (sender.isNotEmpty)
                                      TextSpan(
                                        text: '$sender: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.8)
                                              : const Color(0xFF404040),
                                        ),
                                      ),
                                    TextSpan(text: preview),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _messagePreview(GroupMessageModel? message) {
    if (message == null) return '';
    final text = message.text?.trim();
    if (text != null && text.isNotEmpty) return text;

    final documentTitle = message.sharedDocumentTitle?.trim();
    if (documentTitle != null && documentTitle.isNotEmpty) return documentTitle;

    final fileName = message.fileName?.trim();
    if (fileName != null && fileName.isNotEmpty) return fileName;

    return '';
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group});

  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatarUrl = group.avatarUrl?.trim();

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        image: avatarUrl != null && avatarUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              group.name.isNotEmpty ? group.name[0].toUpperCase() : '',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 0,
              ),
            )
          : null,
    );
  }
}
