enum BillingCycle { monthly, yearly }

enum VipTier { free, pro }

class SubscriptionPlan {
  final String id;
  final String nameVi;
  final String nameEn;
  final String descriptionVi;
  final String descriptionEn;
  final String monthlyPrice;
  final String yearlyPrice;
  final BillingCycle cycle;
  final List<String> featuresVi;
  final List<String> featuresEn;

  const SubscriptionPlan({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.descriptionVi,
    required this.descriptionEn,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.cycle,
    required this.featuresVi,
    required this.featuresEn,
  });

  String getName(String langCode) => langCode == 'vi' ? nameVi : nameEn;
  String getDescription(String langCode) =>
      langCode == 'vi' ? descriptionVi : descriptionEn;
  List<String> getFeatures(String langCode) =>
      langCode == 'vi' ? featuresVi : featuresEn;

  String getPrice() =>
      cycle == BillingCycle.yearly ? yearlyPrice : monthlyPrice;

  String get cycleLabelVi =>
      cycle == BillingCycle.yearly ? '/năm' : '/tháng';
  String get cycleLabelEn =>
      cycle == BillingCycle.yearly ? '/year' : '/month';

  String cycleLabel(String langCode) =>
      langCode == 'vi' ? cycleLabelVi : cycleLabelEn;

  int get savingsPercent {
    final orig = int.tryParse(monthlyPrice.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final yearlyPerMonth = (int.tryParse(yearlyPrice.replaceAll(RegExp(r'[^\d]'), '')) ?? 0) ~/ 12;
    if (orig == 0) return 0;
    return ((orig - yearlyPerMonth) / orig * 100).round();
  }

  static const SubscriptionPlan pro = SubscriptionPlan(
    id: 'pro',
    nameVi: 'VIP',
    nameEn: 'VIP',
    descriptionVi: 'Mở khóa toàn bộ tính năng cao cấp của Sfinity',
    descriptionEn: 'Unlock all premium features of Sfinity',
    monthlyPrice: '49.000',
    yearlyPrice: '399.000',
    cycle: BillingCycle.monthly,
    featuresVi: [
      'Tải tài liệu không giới hạn',
      'Tạo nhóm học tập không giới hạn',
      'Huy hiệu VIP trên hồ sơ',
      'Hỗ trợ ưu tiên',
    ],
    featuresEn: [
      'Unlimited document downloads',
      'Unlimited study groups',
      'VIP badge on profile',
      'Priority support',
    ],
  );
}
