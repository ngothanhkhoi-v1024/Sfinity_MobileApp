import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/group_message_model.dart';
import '../../data/services/group_chat_service.dart';

class GroupFilesTab extends StatefulWidget {
  const GroupFilesTab({
    super.key,
    required this.groupId,
    required this.onShareDocument,
  });

  final String groupId;
  final VoidCallback onShareDocument;

  @override
  State<GroupFilesTab> createState() => _GroupFilesTabState();
}

class _GroupFilesTabState extends State<GroupFilesTab> {
  final _chatService = GroupChatService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.brightness == Brightness.dark ? const Color(0xFF0A0A0A) : cs.surface,
      child: StreamBuilder<List<GroupMessageModel>>(
        stream: _chatService.sharedDocumentsStream(widget.groupId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final docs = snap.data ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tài liệu học tập (${docs.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onShareDocument,
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Chia sẻ tài liệu'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 64,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text('Chưa có tài liệu nào', style: TextStyle(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text(
                              'Nhấn nút chia sẻ để đăng tài liệu lên nhóm!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final docMsg = docs[i];
                          final docId = docMsg.sharedDocumentId ?? '';
                          final docTitle = docMsg.sharedDocumentTitle ?? 'Tài liệu không tên';

                          return Card(
                            elevation: 0,
                            color: cs.surfaceContainerLowest,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              title: Text(
                                docTitle,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Chia sẻ bởi ${docMsg.senderName}',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onSurfaceVariant),
                                onPressed: () {
                                  context.push('/document/$docId');
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
