import 'package:flutter/material.dart';

import '../../../place_reviews/data/models/place_photo_model.dart';

/// Mở xem ảnh phóng to (dùng chung carousel + thumbnail).
void showPlacePhotoViewer(
  BuildContext context,
  List<String> urls, {
  int initialIndex = 0,
}) {
  if (urls.isEmpty) return;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => _FullscreenPhotoViewer(
      urls: urls,
      initialIndex: initialIndex.clamp(0, urls.length - 1),
    ),
  );
}

/// Ảnh carousel đầu trang chi tiết địa điểm — hỗ trợ nhiều ảnh, chấm trang, xem phóng to.
class PlaceDetailPhotoCarousel extends StatefulWidget {
  const PlaceDetailPhotoCarousel({
    super.key,
    required this.photos,
    this.height = 220,
  });

  final List<PlacePhotoModel> photos;
  final double height;

  @override
  State<PlaceDetailPhotoCarousel> createState() => _PlaceDetailPhotoCarouselState();
}

class _PlaceDetailPhotoCarouselState extends State<PlaceDetailPhotoCarousel> {
  PageController? _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ensurePageController();
  }

  @override
  void didUpdateWidget(PlaceDetailPhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.photos.length) {
      _page = 0;
    }
    _ensurePageController();
  }

  void _ensurePageController() {
    if (widget.photos.length > 1) {
      _pageController ??= PageController(viewportFraction: 0.92);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _openFullscreen(int initialIndex) {
    showPlacePhotoViewer(
      context,
      widget.photos.map((p) => p.imageUrl).toList(),
      initialIndex: initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = widget.height;

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
        child: GestureDetector(
          onTap: () => _openFullscreen(0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: _CoverImage(url: photos.first.imageUrl, isDark: isDark),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            key: ValueKey(widget.photos.map((p) => p.id).join(',')),
            controller: _pageController,
            itemCount: photos.length,
            padEnds: false,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: 6,
                ),
                child: GestureDetector(
                  onTap: () => _openFullscreen(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _CoverImage(url: photos[index].imageUrl, isDark: isDark),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < photos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? Colors.white24 : Colors.black26),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '${_page + 1}/${photos.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
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

class _FullscreenPhotoViewer extends StatefulWidget {
  const _FullscreenPhotoViewer({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullscreenPhotoViewer> createState() => _FullscreenPhotoViewerState();
}

class _FullscreenPhotoViewerState extends State<_FullscreenPhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
