import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  late String _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _email = extra?['email']?.toString() ?? '';
    final preset = extra?['code']?.toString();
    if (preset != null && _code.text.isEmpty) _code.text = preset;
  }

  Future<void> _submit() async {
    try {
      await ApiClient.instance.post('/auth/reset-password', {
        'email': _email,
        'code': _code.text.trim(),
        'newPassword': _password.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công')),
        );
        context.go(RouteNames.login);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Email: $_email'),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Mã OTP (6 số)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Đặt lại mật khẩu')),
          ],
        ),
      ),
    );
  }
}
