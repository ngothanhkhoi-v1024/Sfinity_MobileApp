import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/services/subscription_service.dart';
import '../widgets/vip_badge.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _service = SubscriptionService();
  late BillingCycle _selectedCycle;
  SubscriptionStatus? _currentStatus;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _selectedCycle = BillingCycle.monthly;
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _service.getStatus();
    if (mounted) {
      setState(() {
        _currentStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCycle(BillingCycle cycle) async {
    setState(() => _selectedCycle = cycle);
  }

  Future<void> _purchase() async {
    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() => _isPurchasing = true);
    await Future.delayed(const Duration(seconds: 1));
    await _service.purchasePlan(SubscriptionPlan.pro, _selectedCycle);
    await _loadStatus();

    if (mounted) {
      setState(() => _isPurchasing = false);
      _showSuccessDialog();
    }
  }

  Future<bool?> _showConfirmDialog() {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    final plan = SubscriptionPlan.pro;
    final price = _selectedCycle == BillingCycle.yearly
        ? plan.yearlyPrice
        : plan.monthlyPrice;
    final cycleLabel = plan.cycleLabel(langCode);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.confirmPurchase,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.title(context),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan.getName(langCode)} $cycleLabel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.title(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$price VNĐ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.youWillBeRedirected,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.muted(context)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.payNow),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.congratulations,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.title(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              langCode == 'vi'
                  ? 'Bạn đã nâng cấp Pro thành công.'
                  : 'You have successfully upgraded to Pro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.startEnjoying),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    final plan = SubscriptionPlan.pro;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.upgradeVip,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.title(context),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: [
                  if (_currentStatus != null && _currentStatus!.isValid)
                    _CurrentPlanBanner(status: _currentStatus!, langCode: langCode),
                  _ProPlanCard(
                    plan: plan,
                    langCode: langCode,
                    selectedCycle: _selectedCycle,
                    isVip: _currentStatus?.isValid ?? false,
                    isPurchasing: _isPurchasing,
                    onCycleChanged: _selectCycle,
                    onSubscribe: _purchase,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  final SubscriptionStatus status;
  final String langCode;

  const _CurrentPlanBanner({
    required this.status,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.brandHeader(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          VipBadge(tier: VipTier.pro, size: VipBadgeSize.small),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${langCode == 'vi' ? 'Gói Pro hiện tại' : 'Current Pro plan'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.title(context),
                  ),
                ),
                if (status.daysRemaining != null)
                  Text(
                    '${status.daysRemaining} ${l10n.daysRemaining}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String langCode;
  final BillingCycle selectedCycle;
  final bool isVip;
  final bool isPurchasing;
  final ValueChanged<BillingCycle> onCycleChanged;
  final VoidCallback onSubscribe;

  const _ProPlanCard({
    required this.plan,
    required this.langCode,
    required this.selectedCycle,
    required this.isVip,
    required this.isPurchasing,
    required this.onCycleChanged,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final isDark = AppColors.isDark(context);
    final currentPrice = selectedCycle == BillingCycle.yearly
        ? plan.yearlyPrice
        : plan.monthlyPrice;
    final savings = plan.savingsPercent;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              VipBadge(tier: VipTier.pro, size: VipBadgeSize.large),
              const SizedBox(height: 16),
              Text(
                plan.getName(langCode),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                plan.getDescription(langCode),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted(context),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                currentPrice,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'VNĐ${plan.cycleLabel(langCode)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted(context),
                ),
              ),
              if (selectedCycle == BillingCycle.yearly && savings > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    langCode == 'vi'
                        ? 'Tiết kiệm $savings%'
                        : 'Save $savings%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildCycleToggle(context),
              const SizedBox(height: 28),
              const Divider(height: 1),
              const SizedBox(height: 20),
              ...plan.getFeatures(langCode).asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.title(context),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: isPurchasing
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandPill(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: isVip ? null : onSubscribe,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient:
                                isVip ? null : AppColors.brandPill(context),
                            color: isVip ? AppColors.chipBg(context) : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isVip
                                ? (langCode == 'vi'
                                    ? 'Đã là Pro'
                                    : 'Already Pro')
                                : (langCode == 'vi'
                                    ? 'Nâng cấp Pro'
                                    : 'Upgrade to Pro'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isVip
                                  ? AppColors.muted(context)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCycleToggle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.chipBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _CycleButton(
              label: l10n.monthly,
              isActive: selectedCycle == BillingCycle.monthly,
              onTap: () => onCycleChanged(BillingCycle.monthly),
            ),
          ),
          Expanded(
            child: _CycleButton(
              label: l10n.yearly,
              badge: langCode == 'vi' ? 'Tiết kiệm ${plan.savingsPercent}%' : 'Save ${plan.savingsPercent}%',
              isActive: selectedCycle == BillingCycle.yearly,
              onTap: () => onCycleChanged(BillingCycle.yearly),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _CycleButton({
    required this.label,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.card(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppColors.title(context)
                    : AppColors.muted(context),
              ),
            ),
            if (badge != null && !isActive) ...[
              const SizedBox(height: 2),
              Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
