import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
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
    final l10n = context.l10n;
    final ok = await widget.controller.submitCheckIn(
      placeId: widget.placeId,
      placeLat: widget.placeLat,
      placeLng: widget.placeLng,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginToCheckinDesc)),
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
    final l10n = context.l10n;
    final cardBg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
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
              Icon(
                Icons.people_outline,
                size: 20,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.checkinsToday(count),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasCheckedIn) ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.checkInNow,
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
              l10n.loginToCheckinDesc,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push(RouteNames.login),
              child: Text(l10n.pleaseLogin),
            ),
          ] else ...[
            _NearbyHint(controller: ctrl),
            const SizedBox(height: 12),
            _CheckInGradientBar(
              checkInEnabled: !ctrl.checkInSubmitting &&
                  !ctrl.locatingNearby &&
                  ctrl.nearbyCanCheckIn == true,
              checkInLoading: ctrl.checkInSubmitting,
              gpsLoading: ctrl.locatingNearby,
              onCheckIn: _onCheckIn,
              onUpdateGps: ctrl.locatingNearby
                  ? null
                  : () => ctrl.refreshNearby(
                        placeLat: widget.placeLat,
                        placeLng: widget.placeLng,
                      ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckInGradientBar extends StatelessWidget {
  const _CheckInGradientBar({
    required this.checkInEnabled,
    required this.checkInLoading,
    required this.gpsLoading,
    required this.onCheckIn,
    required this.onUpdateGps,
  });

  final bool checkInEnabled;
  final bool checkInLoading;
  final bool gpsLoading;
  final VoidCallback onCheckIn;
  final VoidCallback? onUpdateGps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: checkInEnabled && !checkInLoading ? onCheckIn : null,
                child: Center(
                  child: checkInLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.checkInNow,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 28, color: Colors.white38),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: gpsLoading ? null : onUpdateGps,
                child: Center(
                  child: gpsLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.updateGPS,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
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

class _NearbyHint extends StatelessWidget {
  const _NearbyHint({required this.controller});

  final PlaceEngagementController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          Text(l10n.loading, style: TextStyle(fontSize: 13, color: muted)),
        ],
      );
    }

    final dist = controller.nearbyDistanceM;
    final accuracy = controller.nearbyAccuracyM;
    if (dist == null || accuracy == null) {
      return Text(
        l10n.enableGPSCheckin,
        style: TextStyle(fontSize: 13, color: muted),
      );
    }

    final can = controller.nearbyCanCheckIn == true;

    return Text(
      can ? l10n.enableGPSNearMe : l10n.enableGPSCheckin,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: can ? Colors.green.shade700 : Colors.orange.shade800,
      ),
    );
  }
}
