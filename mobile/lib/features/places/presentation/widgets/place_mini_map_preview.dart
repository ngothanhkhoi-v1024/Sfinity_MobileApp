import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';

/// Bản đồ thu nhỏ trong list tile — không tương tác.
class PlaceMiniMapPreview extends StatelessWidget {
  const PlaceMiniMapPreview({
    super.key,
    required this.point,
    required this.accentColor,
    this.size = 56,
  });

  final LatLng point;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
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
                      width: 22,
                      height: 22,
                      alignment: Alignment.bottomCenter,
                      child: Icon(Icons.place_rounded, color: accentColor, size: 22),
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
