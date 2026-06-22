import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../models/subscription_plan.dart';

class SubscriptionService {
  static const _localKey = 'user_subscription';

  /// URL scheme dùng cho deep link MoMo → Sfinity.
  /// Mặc định `sfinity://payment-callback`, có thể override bằng cách truyền
  /// vào [openMoMoPayment] / lưu env `MOMO_RETURN_SCHEME` (mobile side).
  static const String defaultReturnScheme = 'sfinity://payment-callback';

  /// Cache kết quả cuối cùng từ deep link, để trang đang mở có thể poll.
  static PaymentCallbackPayload? _lastCallback;

  static PaymentCallbackPayload? consumeLastCallback() {
    final c = _lastCallback;
    _lastCallback = null;
    return c;
  }

  static void setLastCallback(PaymentCallbackPayload payload) {
    _lastCallback = payload;
  }

  // -----------------------------------------------------------------------
  // VIP status (server là source of truth, kết hợp cache local để offline)
  // -----------------------------------------------------------------------

  Future<SubscriptionStatus> getStatus() async {
    try {
      final res = await ApiClient.instance.get('/payments/subscription/me');
      final status = SubscriptionStatus(
        isVip: res['isVip'] == true,
        cycle: _parseCycle(res['cycle']),
        expiresAt: _parseDate(res['expiresAt']),
        planId: res['planId'] as String?,
      );
      await saveStatus(status);
      return status;
    } catch (_) {
      return getCachedStatus();
    }
  }

  Future<SubscriptionStatus> getCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_localKey);
      if (data == null) return SubscriptionStatus.free();
      return SubscriptionStatus.fromJson(jsonDecode(data));
    } catch (_) {
      return SubscriptionStatus.free();
    }
  }

  Future<void> saveStatus(SubscriptionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, jsonEncode(status.toJson()));
    } catch (_) {}
  }

  Future<bool> isVip() async {
    final status = await getStatus();
    return status.isVip;
  }

  // -----------------------------------------------------------------------
  // MoMo payment flow
  // -----------------------------------------------------------------------

  /// Phương thức MoMo tạo thanh toán — chọn `qr` để hiển thị QR trong app,
  /// `app` để mở app MoMo qua deeplink (mặc định cũ).
  static const String momoMethodApp = 'captureWallet';
  static const String momoMethodQr = 'payWithMethod';

  /// Tạo yêu cầu thanh toán MoMo trên backend. Trả về thông tin để mở URL
  /// hoặc hiển thị QR.
  ///
  /// [method] mặc định là `momoMethodQr` (`payWithMethod`) — MoMo trả về
  /// `qrCodeUrl` để hiển thị QR trong app. Truyền `momoMethodApp`
  /// (`captureWallet`) nếu muốn flow mở app MoMo cũ.
  Future<MoMoPaymentInfo> createMoMoPayment({
    required SubscriptionPlan plan,
    required BillingCycle cycle,
    String? method,
  }) async {
    final res = await ApiClient.instance.post('/payments/momo/create', {
      'planId': plan.id,
      'cycle': cycle.name,
      if (method != null) 'method': method,
    });
    return MoMoPaymentInfo(
      orderId: res['orderId'] as String,
      requestId: res['requestId'] as String? ?? '',
      amount: (res['amount'] as num?)?.toInt() ?? 0,
      payUrl: res['payUrl'] as String? ?? '',
      deeplink: res['deeplink'] as String?,
      qrCodeUrl: res['qrCodeUrl'] as String?,
    );
  }

  /// Mở URL thanh toán MoMo bằng trình duyệt hoặc app MoMo (ưu tiên deeplink
  /// nếu có). Trả về `true` nếu mở thành công.
  Future<bool> openMoMoPayment(MoMoPaymentInfo info) async {
    final candidates = <Uri>[
      if (info.deeplink != null && info.deeplink!.isNotEmpty)
        Uri.parse(info.deeplink!),
      Uri.parse(info.payUrl),
    ];
    for (final uri in candidates) {
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      } catch (_) {
        // thử URL tiếp theo
      }
    }
    return false;
  }

  /// Poll trạng thái giao dịch từ backend (sau khi deep link trở về).
  Future<MoMoTxStatusResult> checkTransactionStatus(String orderId) async {
    final res = await ApiClient.instance.get('/payments/momo/status/$orderId');
    return MoMoTxStatusResult(
      orderId: res['orderId'] as String,
      status: (res['status'] as String?) ?? 'PENDING',
      amount: (res['amount'] as num?)?.toInt() ?? 0,
      planId: res['planId'] as String?,
      cycle: _parseCycle(res['cycle']),
    );
  }

  /// Hủy / reset local cache khi user muốn "rời Pro" (hiện tại Sfinity không
  /// có flow refund — hàm chỉ xoá cache local; quyền Pro thực sự nằm trên
  /// server theo `vipExpiresAt`).
  Future<void> cancelSubscription() async {
    await saveStatus(SubscriptionStatus.free());
  }

  // -----------------------------------------------------------------------
  // VNPay payment flow
  // -----------------------------------------------------------------------

  /// Tạo yêu cầu thanh toán VNPay trên backend. Trả về paymentUrl để mở
  /// trình duyệt thanh toán.
  Future<VnpayPaymentInfo> createVnpayPayment({
    required SubscriptionPlan plan,
    required BillingCycle cycle,
    String? bankCode,
  }) async {
    final res = await ApiClient.instance.post('/payments/vnpay/create', {
      'planId': plan.id,
      'cycle': cycle.name,
      if (bankCode != null) 'method': bankCode,
    });
    return VnpayPaymentInfo(
      orderId: res['orderId'] as String,
      amount: (res['amount'] as num?)?.toInt() ?? 0,
      paymentUrl: res['paymentUrl'] as String? ?? '',
      orderInfo: res['orderInfo'] as String? ?? '',
      expiresAt: _parseDate(res['expiresAt']),
    );
  }

  /// Mở URL thanh toán VNPay bằng trình duyệt.
  Future<bool> openVnpayPayment(VnpayPaymentInfo info) async {
    try {
      final uri = Uri.parse(info.paymentUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Poll trạng thái giao dịch VNPay từ backend.
  Future<VnpayTxStatusResult> checkVnpayTransactionStatus(String orderId) async {
    final res = await ApiClient.instance.get('/payments/vnpay/status/$orderId');
    return VnpayTxStatusResult(
      orderId: res['orderId'] as String,
      status: (res['status'] as String?) ?? 'PENDING',
      amount: (res['amount'] as num?)?.toInt() ?? 0,
      planId: res['planId'] as String?,
      cycle: _parseCycle(res['cycle']),
    );
  }

  /// Kiểm tra callback từ VNPay (deep link return).
  static PaymentCallbackPayload? consumeVnpayCallback() {
    return _lastCallback;
  }

  static BillingCycle? _parseCycle(dynamic raw) {
    if (raw is String) {
      for (final c in BillingCycle.values) {
        if (c.name == raw) return c;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}

class MoMoPaymentInfo {
  final String orderId;
  final String requestId;
  final int amount;
  final String payUrl;
  final String? deeplink;
  final String? qrCodeUrl;

  const MoMoPaymentInfo({
    required this.orderId,
    required this.requestId,
    required this.amount,
    required this.payUrl,
    this.deeplink,
    this.qrCodeUrl,
  });
}

class MoMoTxStatusResult {
  final String orderId;
  final String status; // PENDING | SUCCESS | FAILED | CANCELED
  final int amount;
  final String? planId;
  final BillingCycle? cycle;

  const MoMoTxStatusResult({
    required this.orderId,
    required this.status,
    required this.amount,
    this.planId,
    this.cycle,
  });

  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED' || status == 'CANCELED';
  bool get isPending => status == 'PENDING';
}

class VnpayPaymentInfo {
  final String orderId;
  final int amount;
  final String paymentUrl;
  final String orderInfo;
  final DateTime? expiresAt;

  const VnpayPaymentInfo({
    required this.orderId,
    required this.amount,
    required this.paymentUrl,
    required this.orderInfo,
    this.expiresAt,
  });
}

class VnpayTxStatusResult {
  final String orderId;
  final String status; // PENDING | SUCCESS | FAILED | CANCELED
  final int amount;
  final String? planId;
  final BillingCycle? cycle;

  const VnpayTxStatusResult({
    required this.orderId,
    required this.status,
    required this.amount,
    this.planId,
    this.cycle,
  });

  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED' || status == 'CANCELED';
  bool get isPending => status == 'PENDING';
}

class PaymentCallbackPayload {
  final String orderId;
  final int? resultCode;
  final String? message;
  final bool isSuccess;

  const PaymentCallbackPayload({
    required this.orderId,
    this.resultCode,
    this.message,
    required this.isSuccess,
  });
}

class SubscriptionStatus {
  final bool isVip;
  final BillingCycle? cycle;
  final DateTime? expiresAt;
  final String? planId;

  const SubscriptionStatus({
    required this.isVip,
    this.cycle,
    this.expiresAt,
    this.planId,
  });

  factory SubscriptionStatus.free() => const SubscriptionStatus(isVip: false);

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
      cycle: _cycleFromName(json['cycle']),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      planId: json['planId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'isVip': isVip,
        'cycle': cycle?.name,
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

  static BillingCycle? _cycleFromName(dynamic name) {
    if (name is String) {
      for (final c in BillingCycle.values) {
        if (c.name == name) return c;
      }
    }
    return null;
  }
}
