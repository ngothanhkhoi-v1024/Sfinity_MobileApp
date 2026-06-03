import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';
import '../controllers/group_controller.dart';
import '../../../profile/presentation/pages/avatar_crop_page.dart';

class GroupFormPage extends StatefulWidget {
  const GroupFormPage({super.key, this.groupId});
  final String? groupId;

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage> {
  late final GroupController _groupCtrl;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPublic = true;
  bool _autoApprove = true;
  String? _avatarUrl;
  File? _pickedAvatar;
  bool _isSaving = false;

  bool get _isEdit => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    _groupCtrl = SfinityApp.groupController;
    if (_isEdit) {
      _loadExistingGroupData();
    }
  }

  void _loadExistingGroupData() {
    final group = _groupCtrl.currentGroup;
    if (group != null && group.id == widget.groupId) {
      _nameCtrl.text = group.name;
      _descCtrl.text = group.description ?? '';
      _isPublic = group.isPublic;
      _autoApprove = group.autoApprove;
      _avatarUrl = group.avatarUrl;
    } else {
      // Fallback if currentGroup isn't loaded or matches
      _groupCtrl.loadGroup(widget.groupId!).then((loaded) {
        if (loaded != null && mounted) {
          setState(() {
            _nameCtrl.text = loaded.name;
            _descCtrl.text = loaded.description ?? '';
            _isPublic = loaded.isPublic;
            _autoApprove = loaded.autoApprove;
            _avatarUrl = loaded.avatarUrl;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
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

  Future<String> _uploadGroupAvatar(File file, String groupOrUserId) async {
    final remoteName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(RegExp(r'[/\\]')).last}';
    final path = 'groups/$groupOrUserId/$remoteName';
    final ref = FirebaseStorage.instance.ref().child(path);
    final snapshot = await ref.putFile(file);
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _avatarUrl;
      if (_pickedAvatar != null) {
        final uid = SfinityApp.auth.user?['id']?.toString() ?? 'unknown';
        avatarUrl = await _uploadGroupAvatar(_pickedAvatar!, _isEdit ? widget.groupId! : uid);
      }

      if (_isEdit) {
        final success = await _groupCtrl.updateGroup(
          widget.groupId!,
          name: name,
          description: _descCtrl.text.trim(),
          isPublic: _isPublic,
          avatarUrl: avatarUrl,
          autoApprove: _autoApprove,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.language == 'Vietnamese' ? 'Cập nhật nhóm thành công!' : 'Group updated successfully!')),
          );
          context.pop();
        }
      } else {
        final group = await _groupCtrl.createGroup(
          name: name,
          description: _descCtrl.text.trim(),
          isPublic: _isPublic,
          autoApprove: _autoApprove,
        );
        if (group != null && mounted) {
          // If avatar was uploaded with temporary UID path, we can update group's avatar path to contain group ID if needed,
          // but temporary group avatar URL is already saved and fully accessible.
          if (_pickedAvatar != null && group.avatarUrl == null) {
            await _groupCtrl.updateGroup(group.id, avatarUrl: avatarUrl);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.language == 'Vietnamese' ? 'Tạo nhóm thành công!' : 'Group created successfully!')),
          );
          context.pop();
          context.push('/groups/${group.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.language == 'Vietnamese' ? 'Lỗi: $e' : 'Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildAvatarSection(ColorScheme cs, bool isDark) {
    final image = _pickedAvatar != null
        ? FileImage(_pickedAvatar!) as ImageProvider
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            ? NetworkImage(_avatarUrl!)
            : null;

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF242526) : cs.surfaceContainerHigh,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.15),
                width: 2,
              ),
              image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
            ),
            child: image == null
                ? Icon(
                    Icons.groups_rounded,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  )
                : null,
          ),
          GestureDetector(
            onTap: _isSaving ? null : _pickAvatar,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [cs.primary, const Color(0xFFFF5A36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : cs.onSurface,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEdit ? l10n.editGroupTitle : l10n.createGroupTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : cs.onSurface,
          ),
        ),
      ),
      body: _isEdit && _groupCtrl.isLoading && _nameCtrl.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatarSection(cs, isDark),
                  const SizedBox(height: 24),

                  // Tên nhóm
                  Text(
                    l10n.groupNameLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: isDark ? Colors.white : cs.onSurface, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: l10n.groupNameHint,
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13.5),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF242526) : cs.surfaceContainerHigh.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mô tả nhóm
                  Text(
                    l10n.groupDescLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: TextStyle(color: isDark ? Colors.white : cs.onSurface, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: l10n.groupDescHint,
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13.5),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF242526) : cs.surfaceContainerHigh.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isDark ? const Color(0xFF1E1E1E) : cs.surfaceContainerHigh.withValues(alpha: 0.3),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : cs.outlineVariant.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Nhóm công khai
                        SwitchListTile(
                          title: Text(
                            l10n.publicGroupLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white.withValues(alpha: 0.9) : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            _isPublic ? l10n.publicGroupHint : l10n.privateGroupHint,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                          ),
                          value: _isPublic,
                          activeColor: cs.primary,
                          onChanged: (v) => setState(() => _isPublic = v),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: isDark ? Colors.white10 : cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                        // Tự động duyệt thành viên
                        SwitchListTile(
                          title: Text(
                            l10n.autoApproveLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white.withValues(alpha: 0.9) : cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            _autoApprove ? l10n.autoApproveHint : l10n.requireApprovalHint,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                          ),
                          value: _autoApprove,
                          activeColor: cs.primary,
                          onChanged: (v) => setState(() => _autoApprove = v),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Nút submit chính
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        colors: [cs.primary, const Color(0xFFFF5A36)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isEdit ? l10n.saveChangesBtn : l10n.createGroupBtn,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút Hủy
                  TextButton(
                    onPressed: _isSaving ? null : () => context.pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.cancelBtn,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF65676B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
