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
  Matrix4? _avatarTransform;
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

    final result = await Navigator.of(context).push<CropResult>(
      MaterialPageRoute(
        builder: (_) => AvatarCropPage(imageFile: File(picked.path)),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _pickedAvatar = result.file;
      _avatarTransform = result.transform;
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

  Widget _buildProfilePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _name.text.isNotEmpty ? _name.text : (SfinityApp.auth.user?['name']?.toString() ?? '—');
    final email = SfinityApp.auth.user?['email']?.toString() ?? '—';

    // Ưu tiên ảnh đã crop, rồi mới đến URL cũ
    final previewImage = _pickedAvatar != null
        ? FileImage(_pickedAvatar!) as ImageProvider
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            ? NetworkImage(_avatarUrl!)
            : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: previewImage != null
                  ? Image(
                      image: previewImage,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1F2937),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Preview',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
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
            _buildProfilePreview(),
            const SizedBox(height: 24),
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
