import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _reason = TextEditingController();
  final _description = TextEditingController();
  String _targetType = 'document';
  final _targetId = TextEditingController();

  Future<void> _submit() async {
    final l10n = context.l10n;
    try {
      await ApiClient.instance.post('/reports', {
        'targetType': _targetType,
        if (_targetId.text.trim().isNotEmpty) 'targetId': _targetId.text.trim(),
        'reason': _reason.text.trim(),
        'description': _description.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportSubmitted)),
        );
        Navigator.pop(context);
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportViolationTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _targetType,
              decoration: InputDecoration(labelText: l10n.type, border: const OutlineInputBorder()),
              items: [
                DropdownMenuItem(value: 'document', child: Text(l10n.documentType)),
                DropdownMenuItem(value: 'user', child: Text(l10n.userType)),
                DropdownMenuItem(value: 'other', child: Text(l10n.otherType)),
              ],
              onChanged: (v) => setState(() => _targetType = v ?? 'document'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetId,
              decoration: InputDecoration(
                labelText: l10n.targetIdOptional,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              decoration: InputDecoration(labelText: l10n.reason, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: InputDecoration(labelText: l10n.detailedDescription, border: const OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: Text(l10n.submitReport)),
          ],
        ),
      ),
    );
  }
}
