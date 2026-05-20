import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';

class ContentFormPage extends StatefulWidget {
  const ContentFormPage({super.key, this.contentId});

  final String? contentId;

  bool get isEdit => contentId != null;

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
      final payload = {'title': _title.text, 'body': _body.text, 'status': 'DRAFT'};
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
      appBar: AppBar(title: Text(widget.isEdit ? 'Sửa nội dung' : 'Tạo nội dung')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Bắt buộc',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder()),
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
