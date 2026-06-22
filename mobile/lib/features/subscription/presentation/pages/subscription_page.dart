import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/services/subscription_service.dart';
import '../widgets/vip_badge.dart';

enum PaymentMethod { momo, vnpay }

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with WidgetsBindingObserver {
  final _service = SubscriptionService();
  late BillingCycle _selectedCycle;
  SubscriptionStatus? _currentStatus;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _pendingOrderId;
  Timer? _pollTimer;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.vnpay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedCycle = BillingCycle.monthly;
    _loadStatus();
    _checkPendingCallback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User quay về từ WebView — kiểm tra callback mới
      _checkPendingCallback();
    }
  }

  Future<void> _loadStatus() async {
    final status = await _service.getStatus();
    await SfinityApp.userLimits.refresh();
    if (!mounted) return;
    setState(() {
      _currentStatus = status;
      _isLoading = false;
    });
    try {
      await SfinityApp.auth.init();
    } catch (_) {}
  }

  /// Khi user quay về app từ MoMo qua deep link, cache sẽ có payload.
  void _checkPendingCallback() {
    final cb = SubscriptionService.consumeLastCallback();
    if (cb == null) return;
    _handleCallback(cb);
  }

  Future<void> _selectCycle(BillingCycle cycle) async {
    if (_isPurchasing) return;
    setState(() => _selectedCycle = cycle);
  }

  Future<void> _selectPaymentMethod(PaymentMethod method) async {
    if (_isPurchasing) return;
    setState(() => _selectedPaymentMethod = method);
  }

  Future<void> _purchase() async {
    if (_isPurchasing) return;
    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() => _isPurchasing = true);
    try {
      if (_selectedPaymentMethod == PaymentMethod.vnpay) {
        // VNPay flow - mở WebView trong app
        final info = await _service.createVnpayPayment(
          plan: SubscriptionPlan.pro,
          cycle: _selectedCycle,
        );
        _pendingOrderId = info.orderId;

        // Điều hướng sang WebView để xử lý thanh toán VNPay
        if (mounted) {
          context.push(RouteNames.vnpayWebview, extra: {
            'paymentUrl': info.paymentUrl,
            'orderId': info.orderId,
          });
        }
      } else {
        // MoMo flow
        final info = await _service.createMoMoPayment(
          plan: SubscriptionPlan.pro,
          cycle: _selectedCycle,
        );
        _pendingOrderId = info.orderId;

        final opened = await _service.openMoMoPayment(info);
        if (!opened && mounted) {
          _showErrorDialog(
            l10nError: 'cannotOpenPaymentApp',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      _showErrorDialog(message: e.toString());
    }
  }

  void _handleCallback(PaymentCallbackPayload cb) {
    _pollTimer?.cancel();
    if (!cb.isSuccess) {
      setState(() {
        _isPurchasing = false;
        _pendingOrderId = null;
      });
      _showErrorDialog(
        l10nError: 'paymentFailed',
        message: cb.message,
      );
      return;
    }

    // Bắt đầu poll trạng thái từ server (đợi IPN cập nhật).
    setState(() => _isPurchasing = true);
    _pollUntilDone(cb.orderId);
  }

  Future<void> _pollUntilDone(String orderId) async {
    const maxAttempts = 30; // ~30s
    var attempt = 0;
    Timer? timer;
    final completer = Completer<void>();

    Future<void> tick() async {
      if (!mounted) {
        completer.complete();
        return;
      }
      attempt++;
      try {
        final status = await _service.checkTransactionStatus(orderId);
        if (status.isSuccess) {
          timer?.cancel();
          _pollTimer = null;
          await _loadStatus();
          if (!mounted) return;
          setState(() {
            _isPurchasing = false;
            _pendingOrderId = null;
          });
          _showSuccessDialog();
          completer.complete();
          return;
        }
        if (status.isFailed) {
          timer?.cancel();
          _pollTimer = null;
          if (!mounted) return;
          setState(() {
            _isPurchasing = false;
            _pendingOrderId = null;
          });
          _showErrorDialog(l10nError: 'paymentFailed');
          completer.complete();
          return;
        }
      } catch (_) {
        // ignore — sẽ retry ở tick sau
      }
      if (attempt >= maxAttempts) {
        timer?.cancel();
        _pollTimer = null;
        if (!mounted) return;
        setState(() => _isPurchasing = false);
        _showErrorDialog(l10nError: 'paymentTimeout');
        completer.complete();
      }
    }

    timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _pollTimer = timer;
    await completer.future;
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.card(context),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payment_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.confirmPurchase,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.chipBg(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${plan.getName(langCode)} $cycleLabel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$price VNĐ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.youWillBeRedirected,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.border(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          color: AppColors.title(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.payNow,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.congratulations,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.title(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              langCode == 'vi'
                  ? 'Bạn đã nâng cấp VIP thành công!'
                  : 'You have successfully upgraded to VIP!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              langCode == 'vi'
                  ? 'Từ bây giờ bạn có thể trải nghiệm các tính năng VIP.'
                  : 'You can now enjoy all VIP features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted(context).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteNames.home);
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  langCode == 'vi' ? 'Bắt đầu trải nghiệm!' : 'Start Enjoying!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog({
    String? message,
    String l10nError = 'paymentFailed',
  }) {
    final l10n = AppLocalizations.of(context);
    final title = switch (l10nError) {
      'cannotOpenPaymentApp' => l10n.cannotOpenPaymentApp,
      'paymentTimeout' => l10n.paymentTimeout,
      _ => l10n.paymentFailed,
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.title(context),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message ?? l10n.paymentFailedDesc,
          style: TextStyle(color: AppColors.muted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.home);
            }
          },
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
                    selectedPaymentMethod: _selectedPaymentMethod,
                    isVip: _currentStatus?.isValid ?? false,
                    isPurchasing: _isPurchasing,
                    onCycleChanged: _selectCycle,
                    onPaymentMethodChanged: _selectPaymentMethod,
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
                  langCode == 'vi' ? 'Gói VIP hiện tại' : 'Current VIP plan',
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
  final PaymentMethod selectedPaymentMethod;
  final bool isVip;
  final bool isPurchasing;
  final ValueChanged<BillingCycle> onCycleChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onSubscribe;

  const _ProPlanCard({
    required this.plan,
    required this.langCode,
    required this.selectedCycle,
    required this.selectedPaymentMethod,
    required this.isVip,
    required this.isPurchasing,
    required this.onCycleChanged,
    required this.onPaymentMethodChanged,
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
              // Chỉ sử dụng phương thức thanh toán VNPay mặc định (Ẩn chọn MoMo)
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
                                    ? 'Đã là VIP'
                                    : 'Already VIP')
                                : (selectedPaymentMethod == PaymentMethod.vnpay
                                    ? (langCode == 'vi'
                                        ? 'Nâng cấp VIP qua VNPay'
                                        : 'Upgrade to VIP with VNPay')
                                    : (langCode == 'vi'
                                        ? 'Nâng cấp VIP qua MoMo'
                                        : 'Upgrade to VIP with MoMo')),
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
              const SizedBox(height: 8),
              if (!isVip)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppColors.muted(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedPaymentMethod == PaymentMethod.vnpay
                          ? (langCode == 'vi'
                              ? 'Thanh toán bảo mật qua VNPay'
                              : 'Secure payment via VNPay')
                          : AppLocalizations.of(context).paymentSecureViaMoMo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
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
