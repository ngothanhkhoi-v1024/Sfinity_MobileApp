import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();

  Future<void> _submit() async {
    final l10n = context.l10n;
    try {
      await ApiClient.instance.post('/auth/change-password', {
        'currentPassword': _current.text,
        'newPassword': _newPassword.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.changePasswordSuccess)),
        );
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _current,
              decoration: InputDecoration(labelText: l10n.currentPassword, border: const OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassword,
              decoration: InputDecoration(labelText: l10n.newPasswordRequired, border: const OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
