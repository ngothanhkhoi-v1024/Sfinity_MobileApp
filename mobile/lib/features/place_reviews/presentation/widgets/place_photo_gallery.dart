import 'package:flutter/material.dart';

import '../../data/models/place_photo_model.dart';
import '../controllers/place_engagement_controller.dart';

class PlacePhotoGallery extends StatelessWidget {
  const PlacePhotoGallery({
    super.key,
    required this.controller,
    required this.placeId,
    required this.photos,
  });

  final PlaceEngagementController controller;
  final String placeId;
  final List<PlacePhotoModel> photos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ảnh thực tế',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.submitting
                  ? null
                  : () => controller.pickAndUploadPhoto(placeId),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: const Text('Thêm ảnh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE8EAED),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_camera_outlined,
                    size: 36, color: Colors.grey.shade500),
                const SizedBox(height: 8),
                Text(
                  'Chưa có ảnh. Thêm ảnh thật để mọi người tin tưởng hơn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => _openFullscreen(context, photo.imageUrl),
                    child: Image.network(
                      photo.imageUrl,
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 160,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
