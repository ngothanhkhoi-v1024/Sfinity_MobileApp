import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/group_chat_service.dart';
import '../widgets/share_document_sheet.dart';

/// Utility class to show the attachment picker menu.
class AttachmentMenu {
  AttachmentMenu._();

  static void show({
    required BuildContext context,
    required Future<void> Function(ImageSource source) onPickImage,
    required Future<void> Function() onPickFile,
    required Future<void> Function() onShareDoc,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Đính kèm',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(
                  icon: Icons.image_rounded,
                  label: 'Thư viện\nảnh',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPickImage(ImageSource.gallery);
                  },
                ),
                _AttachOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Máy\nảnh',
                  color: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPickImage(ImageSource.camera);
                  },
                ),
                _AttachOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Chọn\nfile',
                  color: const Color(0xFFEA580C),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPickFile();
                  },
                ),
                _AttachOption(
                  icon: Icons.menu_book_rounded,
                  label: 'Tài liệu\nhọc tập',
                  color: cs.primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    onShareDoc();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Convenience: show the share-sfinity-doc bottom sheet and send the message.
  static Future<void> showShareDocSheet({
    required BuildContext context,
    required GroupChatService chatService,
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    VoidCallback? onDone,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ShareDocumentSheet(
        onShare: (docId, docTitle) async {
          Navigator.pop(ctx);
          await chatService.shareDocument(
            groupId: groupId,
            senderId: senderId,
            senderName: senderName,
            senderAvatar: senderAvatar,
            documentId: docId,
            documentTitle: docTitle,
          );
          onDone?.call();
        },
      ),
    );
  }
}

// ─── Attachment Option Button ───────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

/// Upload progress bar widget (reusable)
class UploadProgressBar extends StatelessWidget {
  const UploadProgressBar({super.key, required this.progress, this.fileName});
  final double progress;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2.5,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang tải lên${fileName != null ? ': $fileName' : ''}...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  borderRadius: BorderRadius.circular(4),
                  color: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            progress > 0 ? '${(progress * 100).toInt()}%' : '...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
