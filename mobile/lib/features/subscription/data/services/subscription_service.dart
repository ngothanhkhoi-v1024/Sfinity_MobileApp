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

  Future<void> purchasePlan(SubscriptionPlan plan, BillingCycle cycle) async {
    final status = SubscriptionStatus.fromPlan(plan, cycle);
    await saveStatus(status);
  }

  Future<void> cancelSubscription() async {
    await saveStatus(SubscriptionStatus.free());
  }

  Future<bool> isVip() async {
    final status = await getStatus();
    return status.isVip;
  }
}

class SubscriptionStatus {
  final bool isVip;
  final BillingCycle cycle;
  final DateTime? expiresAt;
  final String? planId;

  SubscriptionStatus({
    required this.isVip,
    required this.cycle,
    this.expiresAt,
    this.planId,
  });

  factory SubscriptionStatus.free() => SubscriptionStatus(
        isVip: false,
        cycle: BillingCycle.monthly,
      );

  factory SubscriptionStatus.fromPlan(SubscriptionPlan plan, BillingCycle cycle) {
    final now = DateTime.now();
    final expires = cycle == BillingCycle.yearly
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));
    return SubscriptionStatus(
      isVip: true,
      cycle: cycle,
      expiresAt: expires,
      planId: plan.id,
    );
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isVip: json['isVip'] ?? false,
      cycle: BillingCycle.values.firstWhere(
        (c) => c.name == json['cycle'],
        orElse: () => BillingCycle.monthly,
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      planId: json['planId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'isVip': isVip,
        'cycle': cycle.name,
        'expiresAt': expiresAt?.toIso8601String(),
        'planId': planId,
      };

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isValid => isVip && !isExpired;

  int? get daysRemaining {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
