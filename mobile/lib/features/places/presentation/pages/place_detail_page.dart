import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../place_reviews/presentation/controllers/place_engagement_controller.dart';
import '../../../place_reviews/presentation/widgets/place_checkin_section.dart';
import '../../../place_reviews/presentation/widgets/place_photo_gallery.dart';
import '../../../place_reviews/presentation/widgets/place_rating_section.dart';
import '../controllers/place_detail_controller.dart';
import '../places_map_focus.dart';
import '../widgets/place_directions_section.dart';
import '../widgets/place_tag_chips.dart';

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, required this.placeId});

  final String placeId;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  late final PlaceDetailController _ctrl;
  late final PlaceEngagementController _engagementCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PlaceDetailController();
    _engagementCtrl = PlaceEngagementController();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _engagementCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _ctrl.load(widget.placeId),
      _engagementCtrl.load(widget.placeId),
    ]);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _engagementCtrl.dispose();
    super.dispose();
  }

  void _openUploadDocument(String placeTitle) {
    context.push(
      RouteNames.documentCreate,
      extra: {
        'contentType': 'document',
        'placeId': widget.placeId,
        'placeTitle': placeTitle,
      },
    ).then((_) => _loadAll());
  }

  Future<void> _editPlace() async {
    await context.push('/places/${widget.placeId}/edit');
    if (mounted) _loadAll();
  }

  void _viewOnMap() {
    final place = _ctrl.place;
    final point = place?.point;
    if (place == null || point == null) return;

    PlacesMapFocus.request(
      placeId: place.id,
      lat: point.latitude,
      lng: point.longitude,
    );
    context.go(RouteNames.home);
  }

  Future<void> _deletePlace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa địa điểm?'),
        content: const Text(
          'Địa điểm và liên kết trên bản đồ sẽ bị xóa. Tài liệu đã đăng vẫn giữ trên hệ thống.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _ctrl.deletePlace(widget.placeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa địa điểm')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết địa điểm')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_ctrl.error != null || _ctrl.place == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết địa điểm')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_ctrl.error ?? 'Không tải được địa điểm', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadAll,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final place = _ctrl.place!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMine = _ctrl.isMine();
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết địa điểm'),
        actions: [
          if (isMine) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Sửa địa điểm',
              onPressed: _editPlace,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa địa điểm',
              onPressed: _deletePlace,
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.35 : 0.12),
                    theme.colorScheme.secondary.withValues(alpha: isDark ? 0.2 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.place_rounded, color: primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          place.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Chủ địa điểm',
                    value: place.authorName ?? 'Người dùng',
                    isDark: isDark,
                  ),
                  if (place.address != null && place.address!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Địa chỉ',
                      value: place.address!,
                      isDark: isDark,
                    ),
                  ],
                  if (place.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tiện ích học tập',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PlaceTagDisplay(tagIds: place.tags),
                  ],
                  if (place.body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Mô tả',
                      value: place.body,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            if (place.hasPoint) ...[
              const SizedBox(height: 12),
              PlaceDirectionsSection(
                destination: place.point!,
                accentColor: primary,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _viewOnMap,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(Icons.map_outlined, color: primary),
                label: Text(
                  'Xem địa điểm này trên bản đồ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_engagementCtrl.loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else ...[
              if (place.hasPoint && place.latitude != null && place.longitude != null) ...[
                PlaceCheckInSection(
                  controller: _engagementCtrl,
                  placeId: widget.placeId,
                  placeLat: place.latitude!,
                  placeLng: place.longitude!,
                ),
                const SizedBox(height: 20),
              ],
              if (_engagementCtrl.reviewSummary != null) ...[
              PlaceRatingSection(
                controller: _engagementCtrl,
                placeId: widget.placeId,
                summary: _engagementCtrl.reviewSummary!,
              ),
              const SizedBox(height: 20),
              PlacePhotoGallery(
                controller: _engagementCtrl,
                placeId: widget.placeId,
                photos: _engagementCtrl.photoResult?.photos ?? [],
              ),
              ],
            ],
            if (isMine) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, theme.colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FilledButton.icon(
                  onPressed: () => _openUploadDocument(place.title),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                  label: const Text(
                    'Tải tài liệu cho địa điểm này',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chỉ bạn — chủ địa điểm — mới có thể đăng tài liệu tại đây.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Tài liệu tại địa điểm',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (_ctrl.documents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE8EAED),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 36,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMine
                          ? 'Chưa có tài liệu. Bấm nút phía trên để tải lên.'
                          : 'Chưa có tài liệu công khai ở địa điểm này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._ctrl.documents.map((item) {
                final docId = item['id']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: docId.isEmpty ? null : () => context.push('/document/$docId'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE8EAED),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, color: primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']?.toString() ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Nhấn để xem và tải',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
