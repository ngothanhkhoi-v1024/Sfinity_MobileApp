import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../router/app_router.dart';
import '../../features/subscription/data/services/subscription_service.dart';

/// Lắng nghe deep link `sfinity://payment-callback?orderId=...&resultCode=...`
/// từ MoMo và điều hướng tới trang subscription, đồng thời lưu payload vào
/// [SubscriptionService] để trang subscription xử lý tiếp (poll trạng thái).
class DeepLinkHandler {
  DeepLinkHandler._(this._appLinks);

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  static DeepLinkHandler? _instance;
  static DeepLinkHandler get instance {
    _instance ??= DeepLinkHandler._(AppLinks());
    return _instance!;
  }

  /// Khởi tạo và bắt đầu lắng nghe. Có thể gọi nhiều lần — chỉ thực sự
  /// đăng ký 1 lần.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Cold start: app được mở lần đầu qua deep link.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: getInitialLink error: $e');
    }

    // Warm/hot: app đang chạy và nhận deep link mới.
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) {
        debugPrint('DeepLinkHandler: uriLinkStream error: $e');
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  void _handleUri(Uri uri) {
    debugPrint('DeepLinkHandler: nhận URI $uri');
    if (uri.scheme != 'sfinity') return;
    if (uri.host != 'payment-callback' && uri.path != '/payment-callback') {
      return;
    }
    final orderId = uri.queryParameters['orderId'];
    if (orderId == null || orderId.isEmpty) {
      debugPrint('DeepLinkHandler: thiếu orderId trong deep link');
      return;
    }
    final resultCode = int.tryParse(uri.queryParameters['resultCode'] ?? '');
    final message = uri.queryParameters['message'];
    final isSuccess = resultCode == 0;

    SubscriptionService.setLastCallback(
      PaymentCallbackPayload(
        orderId: orderId,
        resultCode: resultCode,
        message: message,
        isSuccess: isSuccess,
      ),
    );

    // Điều hướng tới trang subscription để trang xử lý payload.
    // Dùng một microtask để tránh gọi router trước khi navigator sẵn sàng.
    Future<void>.microtask(() {
      try {
        AppRouterNavigator.goToSubscription();
      } catch (e) {
        debugPrint('DeepLinkHandler: navigate error: $e');
      }
    });
  }
}

/// Helper gọn để truy cập GoRouter từ DeepLinkHandler mà không cần import
/// vòng tròn. Gán instance khi router được tạo.
class AppRouterNavigator {
  static GoRouterLike? _router;

  static void bind(GoRouterLike router) {
    _router = router;
  }

  static void goToSubscription() {
    _router?.goToSubscription();
  }
}

/// Interface thu gọn để tránh import trực tiếp go_router từ DeepLinkHandler.
abstract class GoRouterLike {
  void goToSubscription();
}
