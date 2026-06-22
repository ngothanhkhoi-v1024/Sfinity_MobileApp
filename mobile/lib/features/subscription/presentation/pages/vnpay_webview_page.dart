import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/route_names.dart';
import '../../data/services/subscription_service.dart';

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
  bool _resultHandled = false;
  InAppWebViewController? _controller;

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
          'Thanh toan VNPay',
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
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        shouldOverrideUrlLoading: (_, navigationAction) async {
          final uri = navigationAction.request.url;
          if (uri == null) return NavigationActionPolicy.ALLOW;

          if (uri.scheme == 'sfinity') {
            _handleDeepLink(uri);
            return NavigationActionPolicy.CANCEL;
          }

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
          if (_resultHandled) return;

          setState(() => _isLoading = false);

          if (!_isVnpayReturnUrl(url)) return;

          // Lay query string tu URL hien tai de goi API
          final queryString = url.queryParameters.isNotEmpty
              ? '?${url.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'
              : '';

          // Goi API backend de lay ket qua thanh toan (tra ve JSON)
          await _fetchPaymentResult(queryString);
        },
        onLoadStart: (_, url) {
          if (url != null) {
            setState(() => _isLoading = true);
          }
        },
        onReceivedError: (_, __, error) {
          debugPrint('[VnpayWebview] Load error: ${error.description}');
          setState(() => _isLoading = false);
        },
      ),
    );
  }

  bool _isVnpayReturnUrl(Uri url) {
    final u = url.toString();
    return u.contains('vnp_ResponseCode') ||
        url.path.contains('vnpay') ||
        url.host.contains('localhost') ||
        url.host.contains('10.0.2.2') ||
        (url.path.contains('return') && u.contains('api'));
  }

  /// Goi API backend /vnpay/return voi Accept: application/json
  /// de lay ket qua thanh toan (transaction da duoc update san trong handleReturn)
  Future<void> _fetchPaymentResult(String queryString) async {
    // Lay baseUrl tu paymentUrl de goi API cung domain
    // VD: https://sfinity-backend-xxx.run.app/api/payments/vnpay/return
    Uri returnApiUri;
    try {
      final paymentUri = Uri.parse(widget.paymentUrl);
      returnApiUri = paymentUri.replace(
        path: '/api/payments/vnpay/return',
        query: queryString.isNotEmpty ? queryString.substring(1) : null,
      );
    } catch (e) {
      debugPrint('[VnpayWebview] Failed to build return URL: $e');
      return;
    }

    debugPrint('[VnpayWebview] Fetching payment result from: $returnApiUri');

    try {
      final dio = Dio();
      final response = await dio.get(
        returnApiUri.toString(),
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] == true;
        final orderId = data['orderId'] as String? ?? widget.orderId;
        final resultCode = data['resultCode'] as String?;
        final message = data['message'] as String? ?? '';

        _onPaymentResult(
          orderId: orderId,
          resultCode: resultCode != null ? int.tryParse(resultCode) : null,
          message: message,
        );
      }
    } catch (e) {
      debugPrint('[VnpayWebview] Failed to fetch payment result: $e');
    }
  }

  void _onPaymentResult({
    required String orderId,
    int? resultCode,
    required String message,
  }) {
    if (_resultHandled) return;
    _resultHandled = true;

    debugPrint('[VnpayWebview] Payment result: code=$resultCode, orderId=$orderId, msg=$message');

    SubscriptionService.setLastCallback(PaymentCallbackPayload(
      orderId: orderId,
      resultCode: resultCode,
      message: message,
      isSuccess: resultCode == 0,
    ));

    // Quay ve subscription page -> poll -> hien ket qua
    context.go(RouteNames.subscription);
  }

  void _handleDeepLink(Uri uri) {
    if (_resultHandled) return;
    debugPrint('[VnpayWebview] Caught deep link: $uri');

    final orderId = uri.queryParameters['orderId'] ?? widget.orderId;
    final resultCode = int.tryParse(uri.queryParameters['resultCode'] ?? '');
    final message = uri.queryParameters['message'];

    _onPaymentResult(
      orderId: orderId,
      resultCode: resultCode,
      message: message ?? 'Thanh toan that bai',
    );
  }

  void _handleCancel() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Huy thanh toan?'),
        content: const Text(
          'Ban co chac muon huy thanh toan khong?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Khong'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huy'),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true && mounted) {
        _resultHandled = true;
        context.go(RouteNames.subscription);
      }
    });
  }
}

