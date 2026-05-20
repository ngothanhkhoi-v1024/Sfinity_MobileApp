import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();
  final _avatar = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = SfinityApp.auth.user;
    _name.text = user?['name']?.toString() ?? '';
    _avatar.text = user?['avatar']?.toString() ?? '';
  }

  Future<void> _submit() async {
    try {
      final updated = await ApiClient.instance.patch('/auth/profile', {
        'name': _name.text.trim(),
        if (_avatar.text.trim().isNotEmpty) 'avatar': _avatar.text.trim(),
      });
      SfinityApp.auth.setUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
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
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _avatar,
              decoration: const InputDecoration(
                labelText: 'Avatar URL (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Lưu')),
          ],
        ),
      ),
    );
  }
}
