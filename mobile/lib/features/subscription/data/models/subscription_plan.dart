enum VipTier { free, starter, pro, elite }

enum BillingCycle { monthly, yearly }

class SubscriptionPlan {
  final String id;
  final String nameVi;
  final String nameEn;
  final String descriptionVi;
  final String descriptionEn;
  final String price;
  final String originalPrice;
  final VipTier tier;
  final BillingCycle cycle;
  final List<String> featuresVi;
  final List<String> featuresEn;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.descriptionVi,
    required this.descriptionEn,
    required this.price,
    required this.originalPrice,
    required this.tier,
    required this.cycle,
    required this.featuresVi,
    required this.featuresEn,
    this.isPopular = false,
  });

  String getName(String langCode) => langCode == 'vi' ? nameVi : nameEn;
  String getDescription(String langCode) =>
      langCode == 'vi' ? descriptionVi : descriptionEn;
  List<String> getFeatures(String langCode) =>
      langCode == 'vi' ? featuresVi : featuresEn;

  int get savingsPercent {
    final orig = int.tryParse(originalPrice.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final curr = int.tryParse(price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (orig == 0) return 0;
    return ((orig - curr) / orig * 100).round();
  }

  static const List<SubscriptionPlan> allPlans = [
    SubscriptionPlan(
      id: 'starter_monthly',
      nameVi: 'Starter',
      nameEn: 'Starter',
      descriptionVi: 'Dành cho người mới bắt đầu',
      descriptionEn: 'For those just getting started',
      price: '49.000',
      originalPrice: '0',
      tier: VipTier.starter,
      cycle: BillingCycle.monthly,
      featuresVi: [
        'Tải tài liệu không giới hạn',
        'Lưu tối đa 20 địa điểm yêu thích',
        'Xem 10 địa điểm nổi bật/ngày',
        'Check-in không giới hạn',
        'Hỗ trợ qua email',
      ],
      featuresEn: [
        'Unlimited document downloads',
        'Save up to 20 favorite places',
        'View 10 featured places/day',
        'Unlimited check-ins',
        'Email support',
      ],
    ),
    SubscriptionPlan(
      id: 'pro_monthly',
      nameVi: 'Pro',
      nameEn: 'Pro',
      descriptionVi: 'Phổ biến nhất — cho sinh viên nghiêm túc',
      descriptionEn: 'Most popular — for serious students',
      price: '99.000',
      originalPrice: '149.000',
      tier: VipTier.pro,
      cycle: BillingCycle.monthly,
      featuresVi: [
        'Tất cả tính năng Starter',
        'Tải tài liệu không giới hạn',
        'Lưu không giới hạn địa điểm yêu thích',
        'Xem không giới hạn địa điểm nổi bật',
        'Tạo tối đa 5 nhóm học tập',
        'Chia sẻ vị trí nhóm',
        'Hỗ trợ ưu tiên',
      ],
      featuresEn: [
        'All Starter features',
        'Unlimited document downloads',
        'Unlimited favorite places',
        'Unlimited featured places',
        'Create up to 5 study groups',
        'Group location sharing',
        'Priority support',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'elite_monthly',
      nameVi: 'Elite',
      nameEn: 'Elite',
      descriptionVi: 'Toàn bộ quyền lực cho người dùng cao cấp',
      descriptionEn: 'Full power for premium users',
      price: '199.000',
      originalPrice: '299.000',
      tier: VipTier.elite,
      cycle: BillingCycle.monthly,
      featuresVi: [
        'Tất cả tính năng Pro',
        'Tạo không giới hạn nhóm học tập',
        'Ẩn quảng cáo hoàn toàn',
        'Huy hiệu Elite trên hồ sơ',
        'Xếp hạng ưu tiên trong top người dùng',
        'Hỗ trợ chat trực tiếp 24/7',
        'Truy cập sớm các tính năng mới',
      ],
      featuresEn: [
        'All Pro features',
        'Unlimited study groups',
        'Completely ad-free experience',
        'Elite badge on profile',
        'Priority ranking in top users',
        '24/7 live chat support',
        'Early access to new features',
      ],
    ),
    SubscriptionPlan(
      id: 'starter_yearly',
      nameVi: 'Starter',
      nameEn: 'Starter',
      descriptionVi: 'Tiết kiệm 30% — thanh toán hàng năm',
      descriptionEn: 'Save 30% — annual billing',
      price: '399.000',
      originalPrice: '588.000',
      tier: VipTier.starter,
      cycle: BillingCycle.yearly,
      featuresVi: [
        'Tải tài liệu không giới hạn',
        'Lưu tối đa 20 địa điểm yêu thích',
        'Xem 10 địa điểm nổi bật/ngày',
        'Check-in không giới hạn',
        'Hỗ trợ qua email',
      ],
      featuresEn: [
        'Unlimited document downloads',
        'Save up to 20 favorite places',
        'View 10 featured places/day',
        'Unlimited check-ins',
        'Email support',
      ],
    ),
    SubscriptionPlan(
      id: 'pro_yearly',
      nameVi: 'Pro',
      nameEn: 'Pro',
      descriptionVi: 'Tiết kiệm 40% — thanh toán hàng năm',
      descriptionEn: 'Save 40% — annual billing',
      price: '799.000',
      originalPrice: '1.188.000',
      tier: VipTier.pro,
      cycle: BillingCycle.yearly,
      featuresVi: [
        'Tất cả tính năng Starter',
        'Tải tài liệu không giới hạn',
        'Lưu không giới hạn địa điểm yêu thích',
        'Xem không giới hạn địa điểm nổi bật',
        'Tạo tối đa 5 nhóm học tập',
        'Chia sẻ vị trí nhóm',
        'Hỗ trợ ưu tiên',
      ],
      featuresEn: [
        'All Starter features',
        'Unlimited document downloads',
        'Unlimited favorite places',
        'Unlimited featured places',
        'Create up to 5 study groups',
        'Group location sharing',
        'Priority support',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'elite_yearly',
      nameVi: 'Elite',
      nameEn: 'Elite',
      descriptionVi: 'Tiết kiệm 45% — thanh toán hàng năm',
      descriptionEn: 'Save 45% — annual billing',
      price: '1.499.000',
      originalPrice: '2.988.000',
      tier: VipTier.elite,
      cycle: BillingCycle.yearly,
      featuresVi: [
        'Tất cả tính năng Pro',
        'Tạo không giới hạn nhóm học tập',
        'Ẩn quảng cáo hoàn toàn',
        'Huy hiệu Elite trên hồ sơ',
        'Xếp hạng ưu tiên trong top người dùng',
        'Hỗ trợ chat trực tiếp 24/7',
        'Truy cập sớm các tính năng mới',
      ],
      featuresEn: [
        'All Pro features',
        'Unlimited study groups',
        'Completely ad-free experience',
        'Elite badge on profile',
        'Priority ranking in top users',
        '24/7 live chat support',
        'Early access to new features',
      ],
    ),
  ];

  static List<SubscriptionPlan> forTier(VipTier tier) =>
      allPlans.where((p) => p.tier == tier).toList();

  static List<SubscriptionPlan> forCycle(BillingCycle cycle) =>
      allPlans.where((p) => p.cycle == cycle).toList();
}
