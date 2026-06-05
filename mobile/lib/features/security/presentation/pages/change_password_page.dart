import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/validators.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final l10n = context.l10n;
    final hasPassword = SfinityApp.auth.user?['hasPassword'] as bool? ?? false;
    try {
      final payload = <String, dynamic>{
        'newPassword': _newPassword.text,
      };
      if (hasPassword) {
        payload['currentPassword'] = _current.text;
      }
      await ApiClient.instance.post('/auth/change-password', payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasPassword ? l10n.changePasswordSuccess : l10n.setPasswordSuccess),
            backgroundColor: Colors.green.shade700,
          ),
        );
        context.pop();

        Future.delayed(const Duration(milliseconds: 300), () {
          final updatedUser = Map<String, dynamic>.from(SfinityApp.auth.user ?? {});
          updatedUser['hasPassword'] = true;
          SfinityApp.auth.setUser(updatedUser);
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e, l10n: l10n))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPassword = SfinityApp.auth.user?['hasPassword'] as bool? ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(hasPassword ? l10n.changePassword : l10n.setPassword)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (hasPassword) ...[
                TextFormField(
                  controller: _current,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return l10n.currentPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _newPassword,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: l10n.newPasswordRequired,
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) => AppValidators.validatePassword(val, l10n: l10n),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(hasPassword ? l10n.save : l10n.setPassword),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
