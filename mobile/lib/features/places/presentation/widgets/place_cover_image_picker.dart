import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

const kMaxPlacePhotos = 10;

class PlaceCoverImagePicker extends StatelessWidget {
  const PlaceCoverImagePicker({
    super.key,
    required this.pickedFiles,
    required this.existingUrls,
    required this.onPick,
    required this.onRemovePicked,
    this.enabled = true,
    this.maxPhotos = kMaxPlacePhotos,
  });

  final List<File> pickedFiles;
  final List<String> existingUrls;
  final VoidCallback onPick;
  final ValueChanged<int> onRemovePicked;
  final bool enabled;
  final int maxPhotos;

  int get _totalCount => existingUrls.length + pickedFiles.length;
  bool get _canAddMore => _totalCount < maxPhotos;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.placeCoverImage,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (_totalCount > 0)
              Text(
                '$_totalCount/$maxPhotos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.placeCoverImageHint,
          style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < existingUrls.length; i++)
                _PhotoThumb(
                  marginRight: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        existingUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => _brokenThumb(isDark),
                      ),
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '✓',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (var i = 0; i < pickedFiles.length; i++)
                _PhotoThumb(
                  marginRight: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(pickedFiles[i], fit: BoxFit.cover),
                      if (enabled)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemovePicked(i),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (enabled && _canAddMore)
                GestureDetector(
                  onTap: onPick,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E4DE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: primary, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          _totalCount == 0 ? l10n.selectPhoto : l10n.addMorePhotos,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_totalCount >= maxPhotos)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.placePhotosMax(maxPhotos),
              style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
            ),
          ),
      ],
    );
  }

  Widget _brokenThumb(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
      child: const Center(child: Icon(Icons.broken_image_outlined, size: 24)),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.child, this.marginRight = 0});

  final Widget child;
  final double marginRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: marginRight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 108, height: 108, child: child),
      ),
    );
  }
}

Future<List<File>> pickPlacePhotos(
  BuildContext context, {
  required int remainingSlots,
}) async {
  if (remainingSlots <= 0) return [];

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
  if (source == null) return [];

  final picker = ImagePicker();
  if (source == ImageSource.gallery) {
    final files = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
      limit: remainingSlots,
    );
    return files.take(remainingSlots).map((x) => File(x.path)).toList();
  }

  final file = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  if (file == null) return [];
  return [File(file.path)];
}

/// Giữ tương thích nếu chỗ khác gọi chọn 1 ảnh.
Future<File?> pickPlaceCoverImage(BuildContext context) async {
  final files = await pickPlacePhotos(context, remainingSlots: 1);
  return files.isEmpty ? null : files.first;
}
