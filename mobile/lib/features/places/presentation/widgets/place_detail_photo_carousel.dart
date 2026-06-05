import 'package:flutter/material.dart';

import '../../../place_reviews/data/models/place_photo_model.dart';

/// Ảnh nền / carousel đầu trang chi tiết địa điểm.
class PlaceDetailPhotoCarousel extends StatelessWidget {
  const PlaceDetailPhotoCarousel({
    super.key,
    required this.photos,
    this.height = 220,
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

    if (photos.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: _CoverImage(url: photos.first.imageUrl, isDark: isDark),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: photos.length,
        padEnds: false,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: 6,
              bottom: 12,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _CoverImage(url: photos[index].imageUrl, isDark: isDark),
            ),
          );
        },
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url, required this.isDark});

  final String url;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E4DE),
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
