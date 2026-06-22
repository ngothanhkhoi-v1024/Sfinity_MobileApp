import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/route_names.dart';
import '../../data/services/subscription_service.dart';

/// Màn hình WebView chạy trong app để xử lý thanh toán VNPay.
/// VNPay redirect về backend return URL, backend trả về HTML chứa
/// deep link `sfinity://payment-vnpay-callback?...`. WebView bắt
/// deep link này và chuyển kết quả về SubscriptionPage.
class VnpayWebviewPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const VnpayWebviewPage({
    super.key,
    required this.paymentUrl,
    required this.orderId,
  });

  @override
  State<VnpayWebviewPage> createState() => _VnpayWebviewPageState();
}

class _VnpayWebviewPageState extends State<VnpayWebviewPage> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => _handleCancel(),
        ),
        title: const Text(
          'Thanh toán VNPay',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: _isLoading
              ? const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A94DA)),
                )
              : const SizedBox(height: 1),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.paymentUrl),
        ),
        initialSettings: InAppWebViewSettings(
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          supportZoom: true,
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
          clearCache: false,
          incognito: false,
        ),
        shouldOverrideUrlLoading: (_, navigationAction) async {
          final uri = navigationAction.request.url;

          if (uri == null) return NavigationActionPolicy.ALLOW;

          if (uri.scheme == 'sfinity') {
            _handleDeepLink(uri);
            return NavigationActionPolicy.CANCEL;
          }

          // Cho phép các URL scheme khác (tel:, mailto:)
          if (!uri.scheme.startsWith('http')) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
        onLoadStop: (_, url) async {
          if (url == null) return;

          setState(() => _isLoading = false);

          // Kiểm tra lại deep link trên URL hiện tại (phòng trường hợp
          // VNPay chuyển hướng không qua shouldOverrideUrlLoading)
          if (url.scheme == 'sfinity') {
            _handleDeepLink(url);
          }
        },
        onWebViewCreated: (_) {},
        onLoadStart: (_, url) {
          if (url != null) {
            setState(() => _isLoading = true);
          }
        },
        onReceivedError: (controller, request, error) {
          debugPrint('[VnpayWebview] Load error: ${error.description}');
          setState(() => _isLoading = false);
        },
      ),
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('[VnpayWebview] Caught deep link: $uri');

    final orderId = uri.queryParameters['orderId'] ?? widget.orderId;
    final resultCode = int.tryParse(uri.queryParameters['resultCode'] ?? '');
    final message = uri.queryParameters['message'];

    // Lưu payload để SubscriptionPage xử lý
    SubscriptionService.setLastCallback(PaymentCallbackPayload(
      orderId: orderId,
      resultCode: resultCode,
      message: message,
      isSuccess: resultCode == 0,
    ));

    // Quay về subscription page để poll và hiển thị kết quả
    context.go(RouteNames.subscription);
  }

  void _handleCancel() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy thanh toán?'),
        content: const Text(
          'Bạn có chắc muốn hủy thanh toán không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy'),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true && mounted) {
        context.go(RouteNames.subscription);
      }
    });
  }
}
