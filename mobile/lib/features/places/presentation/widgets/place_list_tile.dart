import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'place_map_pin.dart';
import 'place_mini_map_preview.dart';

class PlaceListTile extends StatelessWidget {
  const PlaceListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.distanceLabel,
    required this.isCommunity,
    required this.onTap,
    this.isSaved = false,
    this.showMapAction = false,
    this.onMapTap,
    this.mapPoint,
    this.showMiniMap = false,
  });

  final String title;
  final String subtitle;
  final String distanceLabel;
  final bool isCommunity;
  final bool isSaved;
  final VoidCallback onTap;
  final bool showMapAction;
  final VoidCallback? onMapTap;
  final LatLng? mapPoint;
  final bool showMiniMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final accent = isSaved ? const Color(0xFFF59E0B) : (isCommunity ? primary : const Color(0xFF1565C0));
    final pinVariant = isSaved
        ? PlaceMapPinVariant.saved
        : (isCommunity ? PlaceMapPinVariant.community : PlaceMapPinVariant.saved);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (showMiniMap && mapPoint != null)
                  PlaceMiniMapPreview(point: mapPoint!, accentColor: accent, size: 52)
                else
                  SizedBox(
                    width: 40,
                    height: 44,
                    child: PlaceMapPin(variant: pinVariant, size: 40),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          distanceLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (showMapAction && onMapTap != null)
                  Material(
                    color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onMapTap,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.map_rounded, size: 20),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
