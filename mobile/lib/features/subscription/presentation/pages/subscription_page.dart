import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/services/subscription_service.dart';
import '../widgets/plan_card.dart';
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
  String? _selectedPlanId;
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

  List<SubscriptionPlan> get _plansForCycle =>
      SubscriptionPlan.forCycle(_selectedCycle);

  Future<void> _selectCycle(BillingCycle cycle) async {
    setState(() {
      _selectedCycle = cycle;
      _selectedPlanId = null;
    });
  }

  Future<void> _purchase(SubscriptionPlan plan) async {
    final confirm = await _showConfirmDialog(plan);
    if (confirm != true) return;

    setState(() => _isPurchasing = true);

    await Future.delayed(const Duration(seconds: 1));
    await _service.purchasePlan(plan);
    await _loadStatus();

    if (mounted) {
      setState(() => _isPurchasing = false);
      _showSuccessDialog(plan);
    }
  }

  Future<bool?> _showConfirmDialog(SubscriptionPlan plan) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    final price = plan.price;
    final cycleLabel = plan.cycle == BillingCycle.yearly
        ? (langCode == 'vi' ? '/năm' : '/year')
        : (langCode == 'vi' ? '/tháng' : '/month');

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
              '${plan.getName(langCode)}$cycleLabel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.title(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${langCode == 'vi' ? "Giá" : "Price"}: $price VNĐ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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

  void _showSuccessDialog(SubscriptionPlan plan) {
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
                  ? 'Bạn đã nâng cấp lên ${plan.getName(langCode)} thành công.'
                  : 'You have successfully upgraded to ${plan.getName(langCode)}.',
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
    final l10n = context.l10n;
    final langCode = l10n.locale.languageCode;

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
          langCode == 'vi' ? 'Nâng cấp VIP' : 'Upgrade to VIP',
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
          : Column(
              children: [
                if (_currentStatus != null &&
                    _currentStatus!.tier != VipTier.free)
                  _CurrentPlanBanner(
                    status: _currentStatus!,
                    langCode: langCode,
                  ),
                _buildCycleToggle(context, l10n, langCode),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _plansForCycle.length,
                    itemBuilder: (ctx, index) {
                      final plan = _plansForCycle[index];
                      final isYearly =
                          plan.cycle == BillingCycle.yearly;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PlanCard(
                          plan: plan,
                          langCode: langCode,
                          isSelected: _selectedPlanId == plan.id ||
                              (_selectedPlanId == null && index == 0),
                          isCurrentPlan: _currentStatus?.planId ==
                              plan.id,
                          isYearly: isYearly,
                          onTap: () {
                            if (_currentStatus?.planId != plan.id) {
                              setState(() => _selectedPlanId = plan.id);
                            }
                          },
                          onSubscribe: _currentStatus?.planId != plan.id
                              ? () => _purchase(plan)
                              : null,
                          isPurchasing: _isPurchasing,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCycleToggle(
      BuildContext context, AppLocalizations l10n, String langCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.chipBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _CycleButton(
                label: langCode == 'vi' ? 'Hàng tháng' : 'Monthly',
                isActive: _selectedCycle == BillingCycle.monthly,
                onTap: () => _selectCycle(BillingCycle.monthly),
              ),
            ),
            Expanded(
              child: _CycleButton(
                label: langCode == 'vi' ? 'Hàng năm' : 'Yearly',
                isActive: _selectedCycle == BillingCycle.yearly,
                badge: langCode == 'vi' ? 'Tiết kiệm 40%' : 'Save 40%',
                onTap: () => _selectCycle(BillingCycle.yearly),
              ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          VipBadge(tier: status.tier, size: VipBadgeSize.small),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${langCode == 'vi' ? 'Gói hiện tại' : 'Current plan'}: ${status.tierLabel}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.title(context),
                  ),
                ),
                if (status.daysRemaining != null)
                  Text(
                    '${status.daysRemaining} ${langCode == 'vi' ? 'ngày còn lại' : 'days remaining'}',
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
