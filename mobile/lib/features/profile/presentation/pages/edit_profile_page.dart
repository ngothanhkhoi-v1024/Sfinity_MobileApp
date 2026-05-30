import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import 'avatar_crop_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();
  String? _avatarUrl;
  File? _pickedAvatar;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final user = SfinityApp.auth.user;
    _name.text = user?['name']?.toString() ?? '';
    _avatarUrl = user?['avatar']?.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (picked == null) return;
    if (!mounted) return;

    final cropped = await Navigator.of(context).push<File?>(
      MaterialPageRoute(
        builder: (_) => AvatarCropPage(imageFile: File(picked.path)),
      ),
    );

    if (cropped == null || !mounted) return;

    setState(() {
      _pickedAvatar = cropped;
    });
  }

  Future<String> _uploadAvatar(File file) async {
    final userId = SfinityApp.auth.user?['id']?.toString() ?? 'unknown';
    final remoteName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(RegExp(r'[/\\]')).last}';
    final path = 'avatars/$userId/$remoteName';
    final ref = FirebaseStorage.instance.ref().child(path);
    final snapshot = await ref.putFile(file);
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (_uploading) return;

    try {
      setState(() => _uploading = true);

      String? avatarUrl = _avatarUrl;
      if (_pickedAvatar != null) {
        avatarUrl = await _uploadAvatar(_pickedAvatar!);
      }

      final updated = await ApiClient.instance.patch('/auth/profile', {
        'name': _name.text.trim(),
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar': avatarUrl,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật avatar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Widget _buildAvatarPreview() {
    final image = _pickedAvatar != null
        ? FileImage(_pickedAvatar!) as ImageProvider
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            ? NetworkImage(_avatarUrl!)
            : null;

    return CircleAvatar(
      radius: 44,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: image,
      child: image == null ? const Icon(Icons.person, size: 40) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatarPreview(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAvatar,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh từ bộ nhớ'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _uploading ? null : _submit,
              child: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
