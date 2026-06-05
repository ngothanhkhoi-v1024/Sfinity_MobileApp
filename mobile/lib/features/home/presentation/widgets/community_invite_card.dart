import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CommunityInviteCard extends StatelessWidget {
  const CommunityInviteCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }
}

class CommunitySectionHeader extends StatelessWidget {
  const CommunitySectionHeader({
    super.key,
    required this.label,
    required this.isExpanded,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  final String label;
  final bool isExpanded;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted(context),
                  ),
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20,
                color: AppColors.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
