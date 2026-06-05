import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/document_form_controller.dart';
import '../utils/document_state.dart';
import '../widgets/document_upload_section.dart';

class DocumentFormPage extends StatefulWidget {
  const DocumentFormPage({
    super.key,
    this.documentId,
    this.contentType = 'document',
    this.placeId,
    this.placeTitle,
  });

  final String? documentId;
  final String contentType;
  final String? placeId;
  final String? placeTitle;

  bool get isEdit => documentId != null;
  bool get isDocument => contentType == 'document';

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _subjectCode = TextEditingController();

  late final DocumentFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DocumentFormController();
    if (widget.isEdit) {
      _loadExisting();
    } else {
      _controller.loadCategories(null, widget.isEdit);
      if (widget.placeTitle != null && widget.placeTitle!.isNotEmpty) {
        _body.text = '${context.l10n.documentStudyShared} ${widget.placeTitle}';
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _subjectCode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final data = await ApiClient.instance.get('/document/${widget.documentId}');
      _title.text = data['title']?.toString() ?? '';
      _body.text = data['body']?.toString() ?? '';
      _subjectCode.text = data['subjectCode']?.toString() ?? '';
      
      final categoryId = data['categoryId']?.toString();
      _controller.selectCategory(categoryId);

      final fileUrl = data['fileUrl']?.toString() ?? '';
      if (fileUrl.isNotEmpty) {
        _controller.uploadedFileUrl = fileUrl;
        _controller.uploadedFileName = fileUrl.split('/').last.split('?').first;
        _controller.uploadedFileType = data['fileType']?.toString() ?? 'pdf';
        _controller.uploadedFileSize = data['fileSize'] as int?;
      }
      _controller.selectVisibility(
        documentVisibilityOf(Map<String, dynamic>.from(data)),
      );
      await _controller.loadCategories(categoryId, widget.isEdit);
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    try {
      await _controller.pickFile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final l10n = context.l10n;
      final success = await _controller.submit(
        isEdit: widget.isEdit,
        documentId: widget.documentId,
        isDocument: widget.isDocument,
        contentType: widget.contentType,
        title: _title.text.trim(),
        body: _body.text.trim(),
        subjectCode: _subjectCode.text.trim(),

        externalUrl: '',
        placeId: widget.placeId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? l10n.documentUpdateSuccess : l10n.documentShareSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? l10n.editDocument
              : widget.isDocument
                  ? l10n.documentUploadTitle
                  : l10n.shareToGroup,
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.placeTitle != null && widget.placeTitle!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place_outlined, color: primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.loadDocumentFor(widget.placeTitle!),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.isDocument) ...[
                    DocumentUploadSection(
                      controller: _controller,
                      onPickFile: _pickFile,
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextFormField(
                    controller: _title,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: widget.isDocument ? l10n.documentName : l10n.placeName,
                      hintText: widget.isDocument ? l10n.documentNameHint : 'VD: Thư viện Tạ Quang Bửu',
                      prefixIcon: Icon(widget.isDocument ? Icons.bookmark_added_outlined : Icons.place_outlined),
                    ),
                    validator: AppValidators.validateRequired,
                  ),
                  const SizedBox(height: 16),
                  if (widget.isDocument) ...[
                    TextFormField(
                      controller: _subjectCode,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: l10n.subjectCode,
                        hintText: l10n.subjectCodeHint,
                        prefixIcon: const Icon(Icons.book_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _controller.categories.any((cat) => cat['id']?.toString() == _controller.selectedCategoryId)
                          ? _controller.selectedCategoryId
                          : null,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: _controller.categories.map<DropdownMenuItem<String>>((cat) {
                        final name = cat['name']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: cat['id']?.toString(),
                          child: Text(l10n.translateCategory(name)),
                        );
                      }).toList(),
                      onChanged: _controller.selectCategory,
                      validator: (v) => v == null ? l10n.selectCategory : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _controller.selectedVisibility,
                      decoration: InputDecoration(
                        labelText: l10n.displayMode,
                        prefixIcon: const Icon(Icons.visibility_outlined),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: documentVisibilityPublic,
                          child: Text(l10n.publicBadge),
                        ),
                        DropdownMenuItem<String>(
                          value: documentVisibilityPrivate,
                          child: Text(l10n.onlyMe),
                        ),
                      ],
                      onChanged: _controller.selectVisibility,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _body,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: l10n.description,
                      hintText: l10n.documentDescriptionHint,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (v.trim().length < 2) return l10n.documentDescriptionMin;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, theme.colorScheme.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: FilledButton(
                      onPressed: _controller.loading || _controller.uploading ? null : _submitForm,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _controller.loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              widget.isEdit
                                  ? (widget.isDocument ? l10n.updateDocument : l10n.updatePlace)
                                  : l10n.postDocument,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
