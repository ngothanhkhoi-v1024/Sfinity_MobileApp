import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan.dart';

enum VipBadgeSize { small, medium, large }

class VipBadge extends StatelessWidget {
  final VipTier tier;
  final VipBadgeSize size;

  const VipBadge({
    super.key,
    required this.tier,
    this.size = VipBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == VipTier.free) {
      return const SizedBox.shrink();
    }

    final config = _configFor(tier);

    double iconSize;
    double fontSize;
    double paddingH;
    double paddingV;

    switch (size) {
      case VipBadgeSize.small:
        iconSize = 14;
        fontSize = 10;
        paddingH = 6;
        paddingV = 3;
        break;
      case VipBadgeSize.medium:
        iconSize = 18;
        fontSize = 12;
        paddingH = 8;
        paddingV = 4;
        break;
      case VipBadgeSize.large:
        iconSize = 22;
        fontSize = 14;
        paddingH = 12;
        paddingV = 6;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingH,
        vertical: paddingV,
      ),
      decoration: BoxDecoration(
        gradient: config.gradient,
        borderRadius: BorderRadius.circular(size == VipBadgeSize.small ? 6 : 8),
        boxShadow: [
          BoxShadow(
            color: config.gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: iconSize,
            color: Colors.white,
          ),
          SizedBox(width: paddingH * 0.3),
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _configFor(VipTier tier) {
    switch (tier) {
      case VipTier.starter:
        return _BadgeConfig(
          label: 'Starter',
          icon: Icons.star_rounded,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
          ),
        );
      case VipTier.pro:
        return _BadgeConfig(
          label: 'PRO',
          icon: Icons.verified_rounded,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
          ),
        );
      case VipTier.elite:
        return _BadgeConfig(
          label: 'ELITE',
          icon: Icons.diamond_rounded,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
        );
      default:
        return _BadgeConfig(
          label: '',
          icon: Icons.star_rounded,
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final LinearGradient gradient;

  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}
