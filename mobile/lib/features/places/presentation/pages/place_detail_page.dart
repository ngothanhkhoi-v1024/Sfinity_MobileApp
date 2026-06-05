import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../../place_reviews/presentation/controllers/place_engagement_controller.dart';
import '../../../place_reviews/presentation/widgets/place_checkin_section.dart';
import '../../../place_reviews/presentation/widgets/place_photo_gallery.dart';
import '../../../place_reviews/presentation/widgets/place_rating_section.dart';
import '../../data/models/place_model.dart';
import '../controllers/place_detail_controller.dart';
import '../places_map_focus.dart' show PlacesMapFocus, PlacesMapFocusSource;
import '../widgets/place_detail_photo_carousel.dart';
import '../widgets/place_directions_section.dart';
import '../widgets/place_tag_chips.dart';
import '../../../../core/theme/app_colors.dart';

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, required this.placeId});

  final String placeId;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  late final PlaceDetailController _ctrl;
  late final PlaceEngagementController _engagementCtrl;

  bool _isFavorite = false;
  bool _loadingFavorite = true;

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
    // Defer _loadAll sau frame đầu tiên để context.l10n khả dụng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAll();
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([
      // Truy cập context.l10n lazily bên trong callback — an toàn vì lúc này widget đã mounted
      _ctrl.load(widget.placeId, placeNotFound: () => context.l10n.placeNotFound),
      _engagementCtrl.load(widget.placeId),
      _checkFavorite(),
    ]);
  }

  Future<void> _checkFavorite() async {
    if (!SfinityApp.auth.isAuthenticated) {
      if (mounted) setState(() => _loadingFavorite = false);
      return;
    }
    try {
      final favs = await ApiClient.instance.getList('/favorites');
      _isFavorite = favs.any(
        (e) => (e as Map)['documentId']?.toString() == widget.placeId,
      );
    } catch (_) {}
    if (mounted) setState(() => _loadingFavorite = false);
  }

  Future<void> _toggleFavorite() async {
    final l10n = context.l10n;
    if (!SfinityApp.auth.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginToSavePlace)),
        );
      }
      return;
    }
    try {
      if (_isFavorite) {
        await ApiClient.instance.delete('/favorites/${widget.placeId}');
      } else {
        await ApiClient.instance.post('/favorites/${widget.placeId}', {});
      }
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? l10n.favoritePlaceCommunity : l10n.unfavoritePlaceCommunity,
          ),
        ),
      );
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _engagementCtrl.dispose();
    super.dispose();
  }

  void _openUploadDocument(String placeTitle) {
    context
        .push(
          RouteNames.documentCreate,
          extra: {
            'contentType': 'document',
            'placeId': widget.placeId,
            'placeTitle': placeTitle,
          },
        )
        .then((_) => _loadAll());
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
      place: place,
      openSheet: true,
      zoom: 16,
      focusSource: PlacesMapFocusSource.detail,
      pulse: true,
    );
    context.go(RouteNames.home);
  }

  Future<void> _deletePlace() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlace),
        content: Text(l10n.deletePlaceDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelBtn2)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _ctrl.deletePlace(widget.placeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.placeDeleted)),
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
    final l10n = context.l10n;
    if (_ctrl.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.placeDetail)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_ctrl.error != null || _ctrl.place == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.placeDetail)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_ctrl.error ?? l10n.placeNotFound, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadAll,
                  child: Text(l10n.pleaseTryAgain),
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
    final showCommunitySave = !isMine;

    final photos = _engagementCtrl.photoResult?.photos ?? [];

    return Scaffold(
      backgroundColor: isDark ? null : Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.placeDetail,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (!_loadingFavorite)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                color: _isFavorite ? primary : null,
              ),
              tooltip: _isFavorite ? l10n.unfavoritePlace : l10n.favoritePlace,
              onPressed: _toggleFavorite,
            ),
          if (isMine) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editPlace,
              onPressed: _editPlace,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deletePlace,
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
            PlaceDetailPhotoCarousel(photos: photos),
            _PlaceInfoCard(
              place: place,
              theme: theme,
              isDark: isDark,
              primary: primary,
            ),
            const SizedBox(height: 16),
            if (showCommunitySave) ...[
              _SaveCommunityPlaceButton(
                isSaved: _isFavorite,
                loading: _loadingFavorite,
                onPressed: _toggleFavorite,
                primary: primary,
              ),
              const SizedBox(height: 12),
            ],
            if (place.hasPoint) ...[
              PlaceDirectionsSection(
                destination: place.point!,
                accentColor: primary,
                compact: true,
                onViewOnMap: _viewOnMap,
                mapPinHighlighted: true,
              ),
              const SizedBox(height: 20),
            ],
            if (_engagementCtrl.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (place.hasPoint &&
                  place.latitude != null &&
                  place.longitude != null) ...[
                _SectionTitle(
                  icon: Icons.how_to_reg_outlined,
                  title: l10n.interactionCheckin,
                ),
                const SizedBox(height: 8),
                PlaceCheckInSection(
                  controller: _engagementCtrl,
                  placeId: widget.placeId,
                  placeLat: place.latitude!,
                  placeLng: place.longitude!,
                ),
                const SizedBox(height: 20),
              ],
              if (_engagementCtrl.reviewSummary != null) ...[
                _SectionTitle(
                  icon: Icons.groups_outlined,
                  title: l10n.communityContent,
                ),
                const SizedBox(height: 8),
                PlaceRatingSection(
                  controller: _engagementCtrl,
                  placeId: widget.placeId,
                  summary: _engagementCtrl.reviewSummary!,
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PlacePhotoGallery(
                    controller: _engagementCtrl,
                    placeId: widget.placeId,
                    photos: photos,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ],
            if (isMine) ...[
              _SectionTitle(
                icon: Icons.upload_file_outlined,
                title: l10n.managePlace,
              ),
              const SizedBox(height: 8),
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
                  label: Text(
                    l10n.loadDocForPlace,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.holdMapOrButton,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
            ],
            _SectionTitle(
              icon: Icons.menu_book_outlined,
              title: l10n.documentsAtPlace,
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
                      isMine ? l10n.noDocuments : l10n.noDocumentsPlace,
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
                                  Text(
                                    l10n.tapToViewMap,
                                    style: const TextStyle(fontSize: 12),
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

class _SaveCommunityPlaceButton extends StatelessWidget {
  const _SaveCommunityPlaceButton({
    required this.isSaved,
    required this.loading,
    required this.onPressed,
    required this.primary,
  });

  final bool isSaved;
  final bool loading;
  final VoidCallback onPressed;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (loading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: isSaved ? Colors.transparent : primary,
        foregroundColor: isSaved ? primary : Colors.white,
        side: isSaved ? BorderSide(color: primary, width: 1.5) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
        size: 22,
      ),
      label: Text(
        isSaved ? l10n.savedPlace : l10n.savePlace,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }
}

class _PlaceInfoCard extends StatelessWidget {
  const _PlaceInfoCard({
    required this.place,
    required this.theme,
    required this.isDark,
    required this.primary,
  });

  final PlaceModel place;
  final ThemeData theme;
  final bool isDark;
  final Color primary;

  static const _beigeLight = Color(0xFFF8F4EE);
  static const _beigeDark = Color(0xFF2A2824);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _beigeDark : _beigeLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8E0D4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  place.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.person_outline,
            label: l10n.sharedAccount,
            value: place.authorName ?? l10n.anonymous,
            isDark: isDark,
          ),
          if (place.address != null && place.address!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: l10n.address,
              value: place.address!,
              isDark: isDark,
            ),
          ],
          if (place.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l10n.filterAmenities,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            PlaceTagDisplay(tagIds: place.tags),
          ],
          if (place.body.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.format_align_left_rounded,
              label: l10n.placeDescription,
              value: place.body,
              isDark: isDark,
            ),
          ],
        ],
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
