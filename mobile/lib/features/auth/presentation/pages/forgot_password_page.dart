import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _controller = ForgotPasswordController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _email.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await _controller.submit(_email.text.trim());
    if (success && mounted) {
      context.push(RouteNames.otpVerification, extra: {
        'email': _email.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final onSurfaceColor = theme.colorScheme.onSurface;

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
                  child: AuthCard(
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
                          if (_controller.errorMessage != null) ...[
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
                                _controller.errorMessage!,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          AuthTextField(
                            controller: _email,
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: AppValidators.validateEmail,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _controller.isLoading ? null : _submit,
                            child: _controller.isLoading
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
                            onPressed: _controller.isLoading ? null : () => context.pop(),
                            child: const Text('Quay lại đăng nhập'),
                          ),
                        ],
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
