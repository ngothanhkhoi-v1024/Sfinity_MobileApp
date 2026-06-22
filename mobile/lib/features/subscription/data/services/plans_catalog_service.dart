import '../../../../core/network/api_client.dart';
import '../models/subscription_plan.dart';

class PlansCatalogService {
  static String formatVnd(int amount) {
    final digits = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Lấy gói VIP từ backend (giá admin cấu hình). Fallback về mặc định nếu lỗi.
  static Future<SubscriptionPlan> fetchProPlan() async {
    try {
      final res = await ApiClient.instance.get('/plans');
      final plans = res['plans'];
      if (plans is! List || plans.isEmpty) {
        return SubscriptionPlan.pro;
      }

      Map<String, dynamic>? raw;
      for (final item in plans) {
        if (item is Map && item['id'] == 'pro') {
          raw = Map<String, dynamic>.from(item);
          break;
        }
      }
      raw ??= Map<String, dynamic>.from(plans.first as Map);

      final monthly = (raw['monthlyPrice'] as num?)?.toInt() ?? 49000;
      final yearly = (raw['yearlyPrice'] as num?)?.toInt() ?? 399000;
      final name = raw['name']?.toString().trim();
      final nameVi = raw['nameVi']?.toString().trim();
      final displayName = name?.isNotEmpty == true ? name! : 'VIP Pro';
      final displayNameVi = nameVi?.isNotEmpty == true ? nameVi! : displayName;

      return SubscriptionPlan(
        id: raw['id']?.toString() ?? 'pro',
        nameVi: displayNameVi,
        nameEn: displayName,
        descriptionVi: SubscriptionPlan.pro.descriptionVi,
        descriptionEn: SubscriptionPlan.pro.descriptionEn,
        monthlyPrice: formatVnd(monthly),
        yearlyPrice: formatVnd(yearly),
        cycle: BillingCycle.monthly,
        featuresVi: SubscriptionPlan.pro.featuresVi,
        featuresEn: SubscriptionPlan.pro.featuresEn,
      );
    } catch (_) {
      return SubscriptionPlan.pro;
    }
  }
}
