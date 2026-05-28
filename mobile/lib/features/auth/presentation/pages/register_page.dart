import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _controller = RegisterController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await _controller.register(
      _email.text.trim(),
      _password.text,
      _name.text.trim(),
    );
    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.mark_email_unread_rounded, color: Colors.blue, size: 28),
              SizedBox(width: 10),
              Text('Xác thực Email', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Đăng ký tài khoản thành công!\n\nChúng tôi đã gửi một liên kết xác thực đến email của bạn. Vui lòng kiểm tra hộp thư (bao gồm cả thư rác/spam nếu không thấy) và nhấp vào liên kết để kích hoạt tài khoản của bạn trước khi tiến hành đăng nhập.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(RouteNames.login);
              },
              child: const Text('Đã hiểu & Đăng nhập'),
            ),
          ],
        ),
      );
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
        title: const Text('Đăng ký tài khoản'),
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
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Đăng ký',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onSurfaceColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đăng ký tài khoản mới để bắt đầu sử dụng Sfinity.',
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
                            controller: _name,
                            labelText: 'Họ tên',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            validator: AppValidators.validateName,
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _email,
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 14),
                          PasswordField(
                            controller: _password,
                            labelText: 'Mật khẩu',
                            textInputAction: TextInputAction.next,
                            validator: AppValidators.validatePassword,
                          ),
                          const SizedBox(height: 14),
                          PasswordField(
                            controller: _confirmPassword,
                            labelText: 'Xác nhận mật khẩu',
                            validator: (value) => AppValidators.validateConfirmPassword(value, _password.text),
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
                                : const Text('Đăng ký'),
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: _controller.isLoading
                                ? null
                                : () => context.go(RouteNames.login),
                            child: const Text('Đã có tài khoản? Đăng nhập ngay'),
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
