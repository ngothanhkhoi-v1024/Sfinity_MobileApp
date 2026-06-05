import 'package:flutter/material.dart';

import '../../../place_reviews/data/models/place_photo_model.dart';

/// Carousel ảnh đầu trang chi tiết địa điểm.
class PlaceDetailPhotoCarousel extends StatelessWidget {
  const PlaceDetailPhotoCarousel({
    super.key,
    required this.photos,
    this.height = 200,
  });

  final List<PlacePhotoModel> photos;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (photos.isEmpty) {
      return Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E4DE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = photos[index].imageUrl;
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E4DE),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
