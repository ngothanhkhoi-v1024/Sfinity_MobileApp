import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _runAction(() async {
      FocusScope.of(context).unfocus();
      await SfinityApp.auth.login(
        _email.text.trim(),
        _password.text,
      );
      if (mounted) context.go(RouteNames.home);
    });
  }

  Future<void> _loginWithGoogle() async {
    await _runAction(() async {
      await SfinityApp.auth.loginWithGoogle();
      if (mounted) context.go(RouteNames.home);
    });
  }

  Future<void> _loginWithFacebook() async {
    await _runAction(() async {
      await SfinityApp.auth.loginWithFacebook();
      if (mounted) context.go(RouteNames.home);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await action();
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = ApiClient.instance.errorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                                  Icons.lock_person_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Đăng nhập',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: onSurfaceColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chào mừng bạn quay lại với Sfinity.',
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
                              textInputAction: TextInputAction.next,
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
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.key_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Mật khẩu tối thiểu 6 ký tự.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.push(RouteNames.forgotPassword),
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                  : const Text('Đăng nhập'),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: onSurfaceColor.withOpacity(0.14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Hoặc tiếp tục với',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: onSurfaceColor.withOpacity(0.65),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: onSurfaceColor.withOpacity(0.14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _SocialButton(
                              label: 'Đăng nhập với Google',
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
                              borderColor: cardBorderColor,
                              textColor: onSurfaceColor,
                              icon: const _LetterBadge(
                                letter: 'G',
                                background: Color(0xFFEA4335),
                              ),
                              onPressed: _loading ? null : _loginWithGoogle,
                            ),
                            const SizedBox(height: 12),
                            _SocialButton(
                              label: 'Đăng nhập với Facebook',
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
                              borderColor: cardBorderColor,
                              textColor: onSurfaceColor,
                              icon: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFF1877F2),
                                child: Icon(
                                  Icons.facebook_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: _loading ? null : _loginWithFacebook,
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => context.push(RouteNames.register),
                              child: const Text('Chưa có tài khoản? Đăng ký'),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({
    required this.letter,
    required this.background,
  });

  final String letter;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: background,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}