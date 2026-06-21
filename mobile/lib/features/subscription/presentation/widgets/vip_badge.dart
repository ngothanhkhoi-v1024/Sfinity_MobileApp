import 'package:flutter/material.dart';

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
        ),
        borderRadius: BorderRadius.circular(size == VipBadgeSize.small ? 6 : 8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: iconSize,
            color: Colors.white,
          ),
          SizedBox(width: paddingH * 0.3),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
