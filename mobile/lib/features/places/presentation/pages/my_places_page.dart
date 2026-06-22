import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../document/presentation/widgets/document_list_skeleton.dart';
import '../../data/models/place_model.dart';
import '../utils/place_state.dart';
import '../../../../core/constants/place_tags.dart';
import '../../../../core/constants/place_zones.dart';
import '../../../../shared/widgets/app_bar_add_button.dart';
import '../widgets/place_mini_map_preview.dart';

class MyPlacesPage extends StatefulWidget {
  const MyPlacesPage({super.key});

  @override
  State<MyPlacesPage> createState() => _MyPlacesPageState();
}

class _MyPlacesPageState extends State<MyPlacesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<PlaceModel> _allPlaces = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  int _totalCount = 0;
  int _pendingCount = 0;
  int _publishedCount = 0;
  int _rejectedCount = 0;
  int _privateCount = 0;
  int _hiddenCount = 0;

  final List<String> _statuses = ['ALL', 'PRIVATE', 'PENDING', 'PUBLISHED', 'REJECTED', 'HIDDEN'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadPlaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _stateMap(PlaceModel place) => {
        if (place.visibility != null) 'visibility': place.visibility,
        if (place.moderationStatus != null) 'moderationStatus': place.moderationStatus,
        if (place.legacyStatus != null) 'status': place.legacyStatus,
      };

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUserId = SfinityApp.auth.user?['id']?.toString();
      if (currentUserId == null || currentUserId.isEmpty) {
        _allPlaces = [];
      } else {
        _allPlaces = await SfinityApp.placeRepository.listPlaces(
          PlaceListQuery(authorId: currentUserId, limit: 100),
        );
      }
      _calculateStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _calculateStats() {
    _totalCount = _allPlaces.length;
    _pendingCount = 0;
    _publishedCount = 0;
    _rejectedCount = 0;
    _privateCount = 0;
    _hiddenCount = 0;

    for (final place in _allPlaces) {
      final map = _stateMap(place);
      final visibility = placeVisibilityOf(map);
      final moderation = placeModerationStatusOf(map);

      if (visibility == placeVisibilityPrivate) {
        _privateCount++;
      } else if (moderation == placeModerationPending) {
        _pendingCount++;
      } else if (moderation == placeModerationApproved) {
        _publishedCount++;
      } else if (moderation == placeModerationRejected) {
        _rejectedCount++;
      } else if (moderation == placeModerationHidden) {
        _hiddenCount++;
      }
    }
  }

  List<PlaceModel> _getFilteredPlaces(String status) {
    return _allPlaces.where((place) {
      final map = _stateMap(place);
      final visibility = placeVisibilityOf(map);
      final moderation = placeModerationStatusOf(map);

      final matchesTab = switch (status) {
        'ALL' => true,
        'PRIVATE' => visibility == placeVisibilityPrivate,
        'PENDING' =>
          visibility == placeVisibilityPublic && moderation == placeModerationPending,
        'PUBLISHED' =>
          visibility == placeVisibilityPublic && moderation == placeModerationApproved,
        'REJECTED' =>
          visibility == placeVisibilityPublic && moderation == placeModerationRejected,
        'HIDDEN' =>
          visibility == placeVisibilityPublic && moderation == placeModerationHidden,
        _ => false,
      };

      if (!matchesTab) return false;

      if (_searchQuery.isNotEmpty) {
        final title = place.title.toLowerCase();
        final body = place.body.toLowerCase();
        final address = (place.address ?? '').toLowerCase();
        final zone = (place.zone ?? '').toLowerCase();
        final matches = title.contains(_searchQuery) ||
            body.contains(_searchQuery) ||
            address.contains(_searchQuery) ||
            zone.contains(_searchQuery);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _deletePlace(String id) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 36),
        title: Text(l10n.deletePlace, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          l10n.deletePlaceConfirm,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.cancelBtn2, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await SfinityApp.placeRepository.deletePlace(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deletePlace)),
          );
          _loadPlaces();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(
          l10n.myPlaces,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        elevation: 0,
        actions: [
          AppBarAddButton(
            tooltip: l10n.sharePlace,
            onPressed: () async {
              await context.push(RouteNames.placeShare);
              _loadPlaces();
            },
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: DocumentListSkeleton(),
            )
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadPlaces)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsDashboard(primary),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: AppColors.panel(context, radius: 12),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                icon: Icon(Icons.search, color: AppColors.muted(context), size: 20),
                                hintText: l10n.searchPlaceByName,
                                hintStyle: TextStyle(fontSize: 14, color: AppColors.muted(context)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () => _searchController.clear(),
                                        child: Icon(Icons.close, color: AppColors.muted(context), size: 18),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: _statuses.map((status) {
                          final places = _getFilteredPlaces(status);
                          return RefreshIndicator(
                            color: primary,
                            onRefresh: _loadPlaces,
                            child: places.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                    itemCount: places.length,
                                    itemBuilder: (context, index) {
                                      final place = places[index];
                                      return _MyPlaceCard(
                                        place: place,
                                        stateMap: _stateMap(place),
                                        primary: primary,
                                        onTap: () async {
                                          await context.push('/places/${place.id}');
                                          _loadPlaces();
                                        },
                                        onEdit: () async {
                                          await context.push('/places/${place.id}/edit');
                                          _loadPlaces();
                                        },
                                        onDelete: () => _deletePlace(place.id),
                                      );
                                    },
                                  ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off_outlined, size: 48, color: AppColors.muted(context)),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noPlaceYet,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.subtitle(context)),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sharePlaceSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsDashboard(Color primary) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatItem(
            title: l10n.places,
            value: '$_totalCount',
            icon: Icons.location_on_rounded,
            color: primary,
            isSelected: _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.onlyMe,
            value: '$_privateCount',
            icon: Icons.lock_outline_rounded,
            color: Colors.orange.shade700,
            isSelected: _tabController.index == 1,
            onTap: () => _tabController.animateTo(1),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusPending,
            value: '$_pendingCount',
            icon: Icons.hourglass_empty_rounded,
            color: Colors.blue.shade700,
            isSelected: _tabController.index == 2,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusPublished,
            value: '$_publishedCount',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green.shade700,
            isSelected: _tabController.index == 3,
            onTap: () => _tabController.animateTo(3),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusRejected,
            value: '$_rejectedCount',
            icon: Icons.cancel_outlined,
            color: Colors.red.shade700,
            isSelected: _tabController.index == 4,
            onTap: () => _tabController.animateTo(4),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusHidden,
            value: '$_hiddenCount',
            icon: Icons.visibility_off_outlined,
            color: Colors.grey.shade700,
            isSelected: _tabController.index == 5,
            onTap: () => _tabController.animateTo(5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);

    final cardBgColor = isSelected
        ? color
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : Colors.grey[900]);

    final subtitleColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.muted(context);

    final iconColor = isSelected ? Colors.white : color;

    return Material(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(14),
      elevation: isSelected ? 4 : 0,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 86,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : color.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPlaceCard extends StatelessWidget {
  const _MyPlaceCard({
    required this.place,
    required this.stateMap,
    required this.primary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PlaceModel place;
  final Map<String, dynamic> stateMap;
  final Color primary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final address = place.address?.trim().isNotEmpty == true
        ? place.address!
        : (place.zone ?? l10n.places);
    final visibility = placeVisibilityOf(stateMap);
    final moderation = placeModerationStatusOf(stateMap);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppColors.panel(context, radius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (place.hasPoint && place.point != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PlaceMiniMapPreview(
                      point: place.point!,
                      accentColor: primary,
                      size: 50,
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on_rounded, size: 28, color: primary),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (place.zone != null && place.zone!.isNotEmpty) ...[
                            _Badge(
                              text: PlaceZones.byId(place.zone)?.label.toUpperCase() ??
                                  place.zone!.toUpperCase(),
                              color: primary,
                              bgOpacity: 0.08,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (place.tags.isNotEmpty)
                            _Badge(
                              text: PlaceTags.byId(place.tags.first)?.label ??
                                  place.tags.first,
                              color: AppColors.muted(context),
                              backgroundColor: AppColors.chipBg(context),
                            ),
                          const Spacer(),
                          _buildStatusBadge(context, visibility, moderation),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppColors.muted(context), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 100),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.edit, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(fontSize: 13, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String visibility,
    String moderation,
  ) {
    final l10n = context.l10n;
    if (visibility == placeVisibilityPrivate) {
      return _Badge(
        text: l10n.onlyMe,
        color: Colors.orange,
        bgOpacity: 0.1,
      );
    }

    switch (moderation) {
      case placeModerationPending:
        return _Badge(
          text: l10n.statusPending,
          color: Colors.blue,
          bgOpacity: 0.1,
        );
      case placeModerationRejected:
        return _Badge(
          text: l10n.statusRejected,
          color: Colors.red,
          bgOpacity: 0.1,
        );
      case placeModerationHidden:
        return _Badge(
          text: l10n.statusHidden,
          color: Colors.grey,
          bgOpacity: 0.1,
        );
      case placeModerationApproved:
        return _Badge(
          text: l10n.statusPublished,
          color: Colors.green,
          bgOpacity: 0.1,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    this.backgroundColor,
    this.bgOpacity,
  });

  final String text;
  final Color color;
  final Color? backgroundColor;
  final double? bgOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: bgOpacity ?? 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
