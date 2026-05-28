import 'package:flutter/material.dart';
import '../controllers/document_form_controller.dart';

/// Phần giao diện tải tệp lên hoặc nhập liên kết ngoài trong Form đăng tài liệu.
class DocumentUploadSection extends StatelessWidget {
  const DocumentUploadSection({
    super.key,
    required this.controller,
    required this.externalUrlController,
    required this.onPickFile,
  });

  final DocumentFormController controller;
  final TextEditingController externalUrlController;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => controller.setUseUpload(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: controller.useUpload
                        ? primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: controller.useUpload ? primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Tải tệp lên',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: controller.useUpload
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: controller.useUpload ? primary : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => controller.setUseUpload(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !controller.useUpload
                        ? primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: !controller.useUpload ? primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Nhập liên kết ngoài',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: !controller.useUpload
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: !controller.useUpload ? primary : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.useUpload) ...[
          GestureDetector(
            onTap: controller.loading || controller.uploading ? null : onPickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? Colors.grey.shade50
                    : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primary.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    (controller.localFileToUpload != null ||
                            controller.uploadedFileUrl != null)
                        ? Icons.check_circle
                        : Icons.cloud_upload_outlined,
                    size: 44,
                    color: (controller.localFileToUpload != null ||
                            controller.uploadedFileUrl != null)
                        ? Colors.green
                        : primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.uploadedFileName ?? 'Nhấn để chọn file tài liệu',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (controller.localFileToUpload != null ||
                            controller.uploadedFileUrl != null)
                        ? (controller.uploadedFileUrl != null
                            ? 'Tài liệu đã tải lên'
                            : 'Đã chọn tệp (nhấn Đăng tải để tải lên)')
                        : 'Hỗ trợ PDF, DOCX, Hình ảnh...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          if (controller.uploading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: controller.uploadProgress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(controller.uploadProgress * 100).toInt()}%'),
              ],
            ),
          ],
        ] else ...[
          TextFormField(
            controller: externalUrlController,
            decoration: const InputDecoration(
              labelText: 'Nhập liên kết tài liệu (Drive, OneDrive...)',
              hintText: 'https://drive.google.com/file/...',
              prefixIcon: Icon(Icons.link),
            ),
            validator: (v) {
              if (!controller.useUpload && (v == null || v.trim().isEmpty)) {
                return 'Liên kết là bắt buộc';
              }
              if (!controller.useUpload && !v!.startsWith('http')) {
                return 'Liên kết không hợp lệ';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
