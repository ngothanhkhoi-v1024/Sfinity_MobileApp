import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/validators.dart';

class ContentFormPage extends StatefulWidget {
  const ContentFormPage({super.key, this.contentId, this.contentType = 'document'});

  final String? contentId;
  final String contentType;

  bool get isEdit => contentId != null;
  bool get isDocument => contentType == 'document';

  @override
  State<ContentFormPage> createState() => _ContentFormPageState();
}

class _ContentFormPageState extends State<ContentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _load();
  }

  String get _typeTag => widget.isDocument ? 'document' : 'place';

  Future<void> _load() async {
    final data = await ApiClient.instance.get('/content/${widget.contentId}');
    _title.text = data['title']?.toString() ?? '';
    _body.text = data['body']?.toString() ?? '';
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = [
        _body.text.trim(),
        '',
        '---',
        'type:$_typeTag',
      ].join('\n');
      final payload = {'title': _title.text, 'body': body, 'status': 'DRAFT'};
      if (widget.isEdit) {
        await ApiClient.instance.patch('/content/${widget.contentId}', payload);
      } else {
        await ApiClient.instance.post('/content', payload);
      }
      if (mounted) context.pop();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? 'Sửa bài đăng'
              : widget.isDocument
                  ? 'Đăng tài liệu học tập'
                  : 'Chia sẻ địa điểm',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: widget.isDocument ? 'Tên tài liệu / môn học' : 'Tên địa điểm',
                  border: const OutlineInputBorder(),
                ),
                validator: AppValidators.validateRequired,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                labelText: widget.isDocument ? 'Mô tả, link, ghi chú…' : 'Mô tả địa điểm',
                    border: const OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (v) => v != null && v.length >= 2 ? null : 'Bắt buộc',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(widget.isEdit ? 'Cập nhật' : 'Tạo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
