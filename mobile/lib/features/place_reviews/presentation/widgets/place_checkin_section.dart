import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../places/data/utils/place_checkin_geo.dart';
import '../controllers/place_engagement_controller.dart';

class PlaceCheckInSection extends StatefulWidget {
  const PlaceCheckInSection({
    super.key,
    required this.controller,
    required this.placeId,
    required this.placeLat,
    required this.placeLng,
  });

  final PlaceEngagementController controller;
  final String placeId;
  final double placeLat;
  final double placeLng;

  @override
  State<PlaceCheckInSection> createState() => _PlaceCheckInSectionState();
}

class _PlaceCheckInSectionState extends State<PlaceCheckInSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshNearby(
        placeLat: widget.placeLat,
        placeLng: widget.placeLng,
      );
    });
  }

  Future<void> _onCheckIn() async {
    final ok = await widget.controller.submitCheckIn(
      placeId: widget.placeId,
      placeLat: widget.placeLat,
      placeLng: widget.placeLng,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã check-in tại địa điểm này!')),
      );
    } else if (widget.controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl = widget.controller;
    final status = ctrl.checkInStatus;
    final count = status?.checkInCount ?? 0;
    final hasCheckedIn = status?.hasCheckedIn == true;
    final isAuth = SfinityApp.auth.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8EAED),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_reg_rounded,
                  color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  count == 1
                      ? 'người đã check-in'
                      : 'người đã check-in tại đây',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasCheckedIn) ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn đã check-in tại địa điểm này',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!isAuth) ...[
            Text(
              'Đăng nhập để check-in khi bạn đến địa điểm này.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push(RouteNames.login),
              child: const Text('Đăng nhập'),
            ),
          ] else ...[
            _NearbyHint(controller: ctrl),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: ctrl.checkInSubmitting ||
                      ctrl.locatingNearby ||
                      ctrl.nearbyCanCheckIn != true
                  ? null
                  : _onCheckIn,
              icon: ctrl.checkInSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.location_on),
              label: Text(
                ctrl.checkInSubmitting ? 'Đang check-in…' : 'Check-in tại đây',
              ),
            ),
            TextButton.icon(
              onPressed: ctrl.locatingNearby
                  ? null
                  : () => ctrl.refreshNearby(
                        placeLat: widget.placeLat,
                        placeLng: widget.placeLng,
                      ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Cập nhật vị trí GPS'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NearbyHint extends StatelessWidget {
  const _NearbyHint({required this.controller});

  final PlaceEngagementController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    if (controller.locatingNearby) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Đang xác định vị trí…', style: TextStyle(fontSize: 13, color: muted)),
        ],
      );
    }

    final dist = controller.nearbyDistanceM;
    final accuracy = controller.nearbyAccuracyM;
    if (dist == null || accuracy == null) {
      return Text(
        'Bật GPS và đứng gần điểm ghim trên bản đồ để check-in.',
        style: TextStyle(fontSize: 13, color: muted),
      );
    }

    final allowed = PlaceCheckInGeo.allowedRadiusM(accuracy);
    final can = controller.nearbyCanCheckIn == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn cách địa điểm ${dist.round()} m · GPS ±${accuracy.round()} m',
          style: TextStyle(fontSize: 13, color: muted),
        ),
        const SizedBox(height: 4),
        Text(
          can
              ? 'Trong phạm vi check-in (tối đa ${allowed.round()} m).'
              : accuracy > PlaceCheckInGeo.maxAccuracyM
                  ? 'GPS chưa đủ chính xác (tối đa ${PlaceCheckInGeo.maxAccuracyM.round()} m).'
                  : 'Cần đến gần hơn (tối đa ${allowed.round()} m với GPS hiện tại).',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: can ? Colors.green.shade700 : Colors.orange.shade800,
          ),
        ),
      ],
    );
  }
}
