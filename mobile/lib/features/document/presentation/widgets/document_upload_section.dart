import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/document_form_controller.dart';

/// Phần giao diện tải tệp PDF lên và xem trước nội dung trực tiếp khi đăng.
class DocumentUploadSection extends StatelessWidget {
  const DocumentUploadSection({
    super.key,
    required this.controller,
    required this.onPickFile,
  });

  final DocumentFormController controller;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;
    final hasFile = controller.localFileToUpload != null || controller.uploadedFileUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pdfDocument,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.title(context),
          ),
        ),
        const SizedBox(height: 10),
        if (!hasFile) ...[
          GestureDetector(
            onTap: controller.loading || controller.uploading ? null : onPickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.chipBg(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.selectPdfDocument,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.tapToSelectPdf,
                    style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.chipBg(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.uploadedFileName ?? l10n.defaultDocumentFileName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.title(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: controller.loading || controller.uploading ? null : onPickFile,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l10n.changeFile, style: const TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.divider(context)),
                Container(
                  height: 250,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: controller.localFileToUpload != null
                      ? SfPdfViewer.file(
                          controller.localFileToUpload!,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                        )
                      : SfPdfViewer.network(
                          controller.uploadedFileUrl!,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                        ),
                ),
              ],
            ),
          ),
        ],
        if (controller.uploading) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: controller.uploadProgress,
                  backgroundColor: AppColors.border(context),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(controller.uploadProgress * 100).toInt()}%'),
            ],
          ),
        ],
      ],
    );
  }
}
