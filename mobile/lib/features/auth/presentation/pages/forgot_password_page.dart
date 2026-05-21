import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      FocusScope.of(context).unfocus();
      final res = await ApiClient.instance.post('/auth/forgot-password', {
        'email': _email.text.trim(),
      });
      if (!mounted) return;
      final code = res['code']?.toString() ?? '';
      debugPrint('Mã OTP (debug): $code');
      context.push(RouteNames.otpVerification, extra: {
        'email': _email.text.trim(),
      });
    } on DioException catch (e) {
      setState(() => _error = ApiClient.instance.errorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    final cardColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -10,
              child: Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: cardBorderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.4) : const Color(0x0F000000),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                height: 72,
                                width: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Quên mật khẩu',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: onSurfaceColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhập email đã đăng ký để nhận mã OTP khôi phục mật khẩu.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: onSurfaceColor.withOpacity(0.75),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF3B1E22) : const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF6B222C) : const Color(0xFFFDA4AF),
                                  ),
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) {
                                if (value == null || !value.contains('@')) {
                                  return 'Nhập email hợp lệ.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Gửi mã OTP'),
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: _loading ? null : () => context.pop(),
                              child: const Text('Quay lại đăng nhập'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
