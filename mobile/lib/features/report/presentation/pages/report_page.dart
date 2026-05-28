import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _reason = TextEditingController();
  final _description = TextEditingController();
  String _targetType = 'document';
  final _targetId = TextEditingController();

  Future<void> _submit() async {
    try {
      await ApiClient.instance.post('/reports', {
        'targetType': _targetType,
        if (_targetId.text.trim().isNotEmpty) 'targetId': _targetId.text.trim(),
        'reason': _reason.text.trim(),
        'description': _description.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi báo cáo')),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo vi phạm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _targetType,
              decoration: const InputDecoration(labelText: 'Loại', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'document', child: Text('Tài liệu')),
                DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _targetType = v ?? 'document'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetId,
              decoration: const InputDecoration(
                labelText: 'ID đối tượng (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Lý do', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Gửi báo cáo')),
          ],
        ),
      ),
    );
  }
}
