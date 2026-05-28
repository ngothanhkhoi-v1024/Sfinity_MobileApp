import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/document_form_controller.dart';
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
  final _tagsController = TextEditingController();
  final _externalUrlController = TextEditingController();

  late final DocumentFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DocumentFormController();
    _controller.loadCategories(null, widget.isEdit);
    if (widget.isEdit) {
      _loadExisting();
    } else if (widget.placeTitle != null && widget.placeTitle!.isNotEmpty) {
      _body.text = 'Tài liệu học tập tại địa điểm: ${widget.placeTitle}';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _subjectCode.dispose();
    _tagsController.dispose();
    _externalUrlController.dispose();
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
      
      final tagsList = data['tags'] as List? ?? [];
      _tagsController.text = tagsList.join(', ');

      final fileUrl = data['fileUrl']?.toString() ?? '';
      if (fileUrl.isNotEmpty) {
        _controller.uploadedFileUrl = fileUrl;
        _controller.uploadedFileName = fileUrl.split('/').last.split('?').first;
        _controller.uploadedFileType = data['fileType']?.toString() ?? 'pdf';
        _controller.uploadedFileSize = data['fileSize'] as int?;
        if (fileUrl.contains('firebasestorage.googleapis.com') || fileUrl.contains('firebasestorage.app')) {
          _controller.setUseUpload(true);
        } else {
          _controller.setUseUpload(false);
          _externalUrlController.text = fileUrl;
        }
      }
      _controller.loadCategories(categoryId, widget.isEdit);
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
      var bodyText = _body.text.trim();
      if (widget.placeId != null && widget.placeId!.isNotEmpty) {
        bodyText = [
          bodyText,
          '',
          '---',
          'placeId:${widget.placeId}',
        ].join('\n');
      }

      final success = await _controller.submit(
        isEdit: widget.isEdit,
        documentId: widget.documentId,
        isDocument: widget.isDocument,
        contentType: widget.contentType,
        title: _title.text.trim(),
        body: bodyText,
        subjectCode: _subjectCode.text.trim(),
        tagsText: _tagsController.text,
        externalUrl: _externalUrlController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Cập nhật tài liệu thành công!' : 'Chia sẻ tài liệu thành công!'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? 'Sửa tài liệu'
              : widget.isDocument
                  ? 'Đăng tài liệu học tập'
                  : 'Chia sẻ địa điểm',
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
                              'Đang tải tài liệu cho: ${widget.placeTitle}',
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
                      externalUrlController: _externalUrlController,
                      onPickFile: _pickFile,
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextFormField(
                    controller: _title,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: widget.isDocument ? 'Tên tài liệu / môn học' : 'Tên địa điểm',
                      hintText: widget.isDocument ? 'VD: Đề cương Ôn tập Giải tích 1 K68' : 'VD: Thư viện Tạ Quang Bửu',
                      prefixIcon: Icon(widget.isDocument ? Icons.bookmark_added_outlined : Icons.place_outlined),
                    ),
                    validator: AppValidators.validateRequired,
                  ),
                  const SizedBox(height: 16),
                  if (widget.isDocument) ...[
                    TextFormField(
                      controller: _subjectCode,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Mã môn học / học phần',
                        hintText: 'VD: MI1111',
                        prefixIcon: Icon(Icons.code),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _controller.selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục tài liệu',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _controller.categories.map<DropdownMenuItem<String>>((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['id']?.toString(),
                          child: Text(cat['name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: _controller.selectCategory,
                      validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Thẻ từ khóa (Tags)',
                        hintText: 'Cách nhau bằng dấu phẩy, VD: de-thi, giai-tich, k68',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _body,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: widget.isDocument ? 'Mô tả tóm tắt, ghi chú tài liệu...' : 'Mô tả chi tiết địa điểm',
                      hintText: widget.isDocument
                          ? 'Nêu rõ tài liệu gồm những gì, có lời giải hay không...'
                          : 'Nêu thông tin về WiFi, ổ cắm điện, giờ mở cửa...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (v) => v != null && v.trim().length >= 2 ? null : 'Mô tả tối thiểu 2 ký tự',
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
                          : Text(widget.isEdit ? 'Cập nhật tài liệu' : 'Đăng tài liệu ngay'),
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
