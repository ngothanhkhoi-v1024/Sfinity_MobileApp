import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/social_login_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _controller = LoginController();

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
    _password.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await _controller.login(
      _email.text.trim(),
      _password.text,
    );
    if (success && mounted) {
      context.go(RouteNames.home);
    }
  }

  Future<void> _loginWithGoogle() async {
    final success = await _controller.loginWithGoogle();
    if (success && mounted) {
      context.go(RouteNames.home);
    }
  }

  Future<void> _loginWithFacebook() async {
    final success = await _controller.loginWithFacebook();
    if (success && mounted) {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final onSurfaceColor = theme.colorScheme.onSurface;
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
                                Icons.lock_person_rounded,
                                color: Colors.white,
                                size: 34,
                                       ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l10n.login,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onSurfaceColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.welcomeBack,
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
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 14),
                          PasswordField(
                            controller: _password,
                            labelText: l10n.password,
                            validator: AppValidators.validateLoginPassword,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _controller.isLoading
                                  ? null
                                    : () => context.push(RouteNames.forgotPassword),
                                  child: Text(l10n.forgotPasswordQuestion),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                                : Text(l10n.login),
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
                                  l10n.orContinueWith,
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
                          SocialLoginButton(
                            label: l10n.continueWithGoogle,
                            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
                            borderColor: cardBorderColor,
                            textColor: onSurfaceColor,
                            icon: const _LetterBadge(
                              letter: 'G',
                              background: Color(0xFFEA4335),
                            ),
                            onPressed: _controller.isLoading ? null : _loginWithGoogle,
                          ),
                          const SizedBox(height: 12),
                          // SocialLoginButton(
                          //   label: 'Đăng nhập với Facebook',
                          //   color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
                          //   borderColor: cardBorderColor,
                          //   textColor: onSurfaceColor,
                          //   icon: const CircleAvatar(
                          //     radius: 12,
                          //     backgroundColor: Color(0xFF1877F2),
                          //     child: Icon(
                          //       Icons.facebook_rounded,
                          //       size: 16,
                          //       color: Colors.white,
                          //     ),
                          //   ),
                          //   onPressed: _controller.isLoading ? null : _loginWithFacebook,
                          // ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: _controller.isLoading
                                ? null
                                : () => context.push(RouteNames.register),
                            child: Text(l10n.noAccountYetRegister),
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
