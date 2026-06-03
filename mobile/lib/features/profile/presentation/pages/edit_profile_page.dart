import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/data/services/firestore_user_service.dart';
import 'avatar_crop_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();
  final _address = TextEditingController();

  String? _avatarUrl;
  File? _pickedAvatar;
  DateTime? _birthDate;
  String _gender = 'Khác';

  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final user = SfinityApp.auth.user;
    _name.text = user?['name']?.toString() ?? '';
    _address.text = user?['address']?.toString() ?? '';

    final avatar = user?['avatar']?.toString();
    if (avatar != null && avatar.isNotEmpty) {
      _avatarUrl = avatar;
    }

    final birthStr = user?['birthDate']?.toString();
    if (birthStr != null && birthStr.isNotEmpty) {
      _birthDate = DateTime.tryParse(birthStr);
    }

    final gender = user?['gender']?.toString();
    if (gender != null && ['Nam', 'Nữ', 'Khác'].contains(gender)) {
      _gender = gender;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 5),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_uploading) return;

    try {
      setState(() => _uploading = true);

      String? avatarUrl = _avatarUrl;
      if (_pickedAvatar != null) {
        avatarUrl = await _uploadAvatar(_pickedAvatar!);
      }

      final payload = <String, dynamic>{
        'name': _name.text.trim(),
      };
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        payload['avatar'] = avatarUrl;
      }
      if (_birthDate != null) {
        payload['birthDate'] = _formatDate(_birthDate!);
      }
      payload['gender'] = _gender;
      payload['address'] = _address.text.trim();

      final updated = await ApiClient.instance.patch('/auth/profile', payload);

      final rawUser = updated.containsKey('user') ? updated['user'] : updated;
      final userData = rawUser is Map<String, dynamic> ? rawUser : updated;

      // Preserve avatar on client side if API doesn't echo it back.
      final merged = Map<String, dynamic>.from(userData);
      if (merged['avatar'] == null && avatarUrl != null && avatarUrl.isNotEmpty) {
        merged['avatar'] = avatarUrl;
      }
      if (merged['avatar'] != null && merged['avatar'].toString().isNotEmpty) {
        final base = merged['avatar'].toString().split('?').first;
        merged['avatar'] = '$base?v=${DateTime.now().millisecondsSinceEpoch}';
      }
      SfinityApp.auth.setUser(merged);

      // Sync extra fields to Firestore
      try {
        final firestoreService = FirestoreUserService();
        await firestoreService.syncUserProfile(
          uid: merged['id']?.toString() ?? SfinityApp.auth.user?['id']?.toString() ?? '',
          displayName: _name.text.trim(),
          photoUrl: avatarUrl,
          birthDate: _birthDate != null ? _formatDate(_birthDate!) : null,
          gender: _gender,
          address: _address.text.trim(),
        );
      } catch (_) {}

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
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Widget _buildAvatarPreview() {
    return Stack(
      children: [
        _AvatarCircle(
          image: _pickedAvatar,
          url: _avatarUrl,
          radius: 56,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              onPressed: _uploading ? null : _pickAvatar,
              tooltip: 'Chọn ảnh',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _name.text.isNotEmpty ? _name.text : (SfinityApp.auth.user?['name']?.toString() ?? '—');
    final email = SfinityApp.auth.user?['email']?.toString() ?? '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _AvatarCircle(
            image: _pickedAvatar,
            url: _avatarUrl,
            size: 56,
            showBackground: true,
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: _uploading ? null : _pickAvatar,
              child: const Text('Chọn ảnh từ bộ nhớ'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Họ tên',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Giới tính',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'Khác'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _birthDate != null
                          ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                          : 'Chọn ngày sinh',
                      style: TextStyle(
                        color: _birthDate != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
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

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    this.image,
    this.url,
    this.radius,
    this.size,
    this.showBackground = false,
  });

  final File? image;
  final String? url;
  final double? radius;
  final double? size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null || (url != null && url!.isNotEmpty);

    if (!hasImage) {
      final effectiveSize = radius != null ? radius! * 2 : size ?? 56;
      return Container(
        width: effectiveSize,
        height: effectiveSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: effectiveSize * 0.4,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    final provider = image != null
        ? FileImage(image!) as ImageProvider
        : NetworkImage(url!);

    final effectiveSize = radius != null ? radius! * 2 : size ?? 80;

    Widget imageWidget = Image(
      image: provider,
      fit: BoxFit.cover,
      width: effectiveSize,
      height: effectiveSize,
    );

    return ClipOval(
      child: SizedBox(
        width: effectiveSize,
        height: effectiveSize,
        child: imageWidget,
      ),
    );
  }
}
