import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan.dart';
import 'vip_badge.dart';

class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String langCode;
  final bool isSelected;
  final bool isCurrentPlan;
  final bool isYearly;
  final VoidCallback onTap;
  final VoidCallback? onSubscribe;
  final bool isPurchasing;

  const PlanCard({
    super.key,
    required this.plan,
    required this.langCode,
    required this.isSelected,
    required this.isCurrentPlan,
    required this.isYearly,
    required this.onTap,
    this.onSubscribe,
    this.isPurchasing = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primary
                : (isCurrentPlan ? AppColors.secondary : AppColors.border(context)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(
                        alpha: AppColors.isDark(context) ? 0.2 : 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.isPopular && isYearly) _PopularBanner(context),
            _PlanHeader(context, primary),
            _PriceSection(context, primary),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _FeaturesSection(context),
            if (isCurrentPlan)
              _CurrentPlanIndicator(context)
            else
              _SubscribeButton(context, primary),
          ],
        ),
      ),
    );
  }

  Widget _PopularBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Text(
        l10n.mostPopular,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _PlanHeader(BuildContext context, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          VipBadge(tier: plan.tier, size: VipBadgeSize.medium),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.getName(langCode),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.title(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan.getDescription(langCode),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (plan.savingsPercent > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${plan.savingsPercent}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _PriceSection(BuildContext context, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            plan.price,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'VNĐ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.muted(context),
              ),
            ),
          ),
          if (plan.originalPrice != '0') ...[
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                plan.originalPrice,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted(context),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.muted(context),
                ),
              ),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              plan.cycle == BillingCycle.yearly
                  ? (langCode == 'vi' ? '/năm' : '/year')
                  : (langCode == 'vi' ? '/tháng' : '/month'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _FeaturesSection(BuildContext context) {
    final features = plan.getFeatures(langCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            _FeatureItem(
              text: features[i],
              isHighlight: i < 2,
            ),
            if (i < features.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _CurrentPlanIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.chipBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.currentPlan_,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.muted(context),
          ),
        ),
      ),
    );
  }

  Widget _SubscribeButton(BuildContext context, Color primary) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: isPurchasing
            ? Container(
                decoration: BoxDecoration(
                  gradient: AppColors.brandPill(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            : GestureDetector(
                onTap: onSubscribe,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        isSelected ? AppColors.brandPill(context) : null,
                    color: isSelected ? null : AppColors.chipBg(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.chooseThisPlan,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.muted(context),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final bool isHighlight;

  const _FeatureItem({
    required this.text,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: isHighlight ? AppColors.primary : AppColors.muted(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w500 : FontWeight.w400,
              color: AppColors.title(context),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
