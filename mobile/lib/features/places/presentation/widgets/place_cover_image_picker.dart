import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class PlaceCoverImagePicker extends StatelessWidget {
  const PlaceCoverImagePicker({
    super.key,
    required this.pickedFile,
    required this.previewUrl,
    required this.onPick,
    required this.onClear,
    this.enabled = true,
  });

  final File? pickedFile;
  final String? previewUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    final hasImage =
        pickedFile != null || (previewUrl != null && previewUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.placeCoverImage,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.placeCoverImageHint,
          style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: enabled ? onPick : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 160,
              width: double.infinity,
              color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E4DE),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (pickedFile != null)
                    Image.file(pickedFile!, fit: BoxFit.cover)
                  else if (previewUrl != null && previewUrl!.isNotEmpty)
                    Image.network(
                      previewUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(context),
                    )
                  else
                    _placeholder(context),
                  if (enabled)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Material(
                        color: AppColors.primaryOf(context).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onPick,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.selectPhoto,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasImage && enabled) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 16),
              label: Text(l10n.removeCoverImage),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: AppColors.muted(context),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.selectPhoto,
            style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
          ),
        ],
      ),
    );
  }
}

Future<File?> pickPlaceCoverImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(context.l10n.photoLibrary),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(context.l10n.camera),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: source,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  if (file == null) return null;
  return File(file.path);
}
