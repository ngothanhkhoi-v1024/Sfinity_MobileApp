import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import 'place_map_pin.dart';

/// Bản đồ thu nhỏ trong list tile — không tương tác.
class PlaceMiniMapPreview extends StatelessWidget {
  const PlaceMiniMapPreview({
    super.key,
    required this.point,
    required this.accentColor,
    this.size = 56,
    this.highlighted = false,
  });

  final LatLng point;
  final Color accentColor;
  final double size;

  /// Pin xanh lá khi đang xem / chọn địa điểm này.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final pinColor = highlighted ? PlaceMapPin.selectedColor : accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: highlighted
                ? PlaceMapPin.selectedColor.withValues(alpha: 0.55)
                : accentColor.withValues(alpha: 0.2),
            width: highlighted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.tileUrlTemplate,
                  userAgentPackageName: MapConfig.userAgentPackageName,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: highlighted ? 36 : 28,
                      height: highlighted ? 36 : 28,
                      alignment: Alignment.bottomCenter,
                      child: highlighted
                          ? const PlaceMapPin(
                              variant: PlaceMapPinVariant.highlightedCommunity,
                              size: 36,
                            )
                          : Icon(Icons.location_on_rounded, color: pinColor, size: 24),
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
}
