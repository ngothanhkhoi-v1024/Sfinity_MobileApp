import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_plan.dart';

class SubscriptionService {
  static const _key = 'user_subscription';

  Future<SubscriptionStatus> getStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data == null) return SubscriptionStatus.free();
      return SubscriptionStatus.fromJson(jsonDecode(data));
    } catch (_) {
      return SubscriptionStatus.free();
    }
  }

  Future<void> saveStatus(SubscriptionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(status.toJson()));
    } catch (_) {}
  }

  Future<void> purchasePlan(SubscriptionPlan plan) async {
    final status = SubscriptionStatus.fromPlan(plan);
    await saveStatus(status);
  }

  Future<void> cancelSubscription() async {
    await saveStatus(SubscriptionStatus.free());
  }

  Future<bool> isVip() async {
    final status = await getStatus();
    return status.tier != VipTier.free;
  }

  Future<bool> hasFeature(String featureKey) async {
    final status = await getStatus();
    switch (featureKey) {
      case 'unlimited_downloads':
        return status.tier == VipTier.starter ||
            status.tier == VipTier.pro ||
            status.tier == VipTier.elite;
      case 'unlimited_favorites':
        return status.tier == VipTier.pro || status.tier == VipTier.elite;
      case 'unlimited_places':
        return status.tier == VipTier.pro || status.tier == VipTier.elite;
      case 'unlimited_groups':
        return status.tier == VipTier.elite;
      case 'no_ads':
        return status.tier == VipTier.elite;
      case 'elite_badge':
        return status.tier == VipTier.elite;
      case 'priority_support':
        return status.tier == VipTier.pro || status.tier == VipTier.elite;
      default:
        return status.tier == VipTier.elite;
    }
  }
}

class SubscriptionStatus {
  final VipTier tier;
  final BillingCycle cycle;
  final DateTime? expiresAt;
  final String? planId;
  final bool isActive;

  SubscriptionStatus({
    required this.tier,
    required this.cycle,
    this.expiresAt,
    this.planId,
    this.isActive = true,
  });

  factory SubscriptionStatus.free() => SubscriptionStatus(
        tier: VipTier.free,
        cycle: BillingCycle.monthly,
        isActive: false,
      );

  factory SubscriptionStatus.fromPlan(SubscriptionPlan plan) {
    final now = DateTime.now();
    final expires = plan.cycle == BillingCycle.monthly
        ? now.add(const Duration(days: 30))
        : now.add(const Duration(days: 365));
    return SubscriptionStatus(
      tier: plan.tier,
      cycle: plan.cycle,
      expiresAt: expires,
      planId: plan.id,
      isActive: true,
    );
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: VipTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => VipTier.free,
      ),
      cycle: BillingCycle.values.firstWhere(
        (c) => c.name == json['cycle'],
        orElse: () => BillingCycle.monthly,
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      planId: json['planId'],
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'cycle': cycle.name,
        'expiresAt': expiresAt?.toIso8601String(),
        'planId': planId,
        'isActive': isActive,
      };

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isValid => isActive && !isExpired;

  String get tierLabel {
    switch (tier) {
      case VipTier.free:
        return 'Miễn phí';
      case VipTier.starter:
        return 'Starter';
      case VipTier.pro:
        return 'Pro';
      case VipTier.elite:
        return 'Elite';
    }
  }

  String get cycleLabel {
    return cycle == BillingCycle.yearly ? 'Năm' : 'Tháng';
  }

  int? get daysRemaining {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
