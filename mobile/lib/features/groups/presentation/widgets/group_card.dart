import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
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
    final preview = _messagePreview(message);
    final sender = message?.senderName.trim() ?? '';
    final time = message == null ? '' : DateFormat('HH:mm').format(message!.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                _GroupAvatar(group: group),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.title(context),
                              ),
                            ),
                          ),
                          if (time.isNotEmpty)
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted(context),
                              ),
                            ),
                        ],
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sender.isNotEmpty ? '$sender: $preview' : preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ],
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
    final primary = AppColors.primaryOf(context);
    final avatarUrl = group.avatarUrl?.trim();

    return CircleAvatar(
      radius: 22,
      backgroundColor: primary.withValues(alpha: 0.08),
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            )
          : null,
    );
  }
}
