import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';

class ReportPage extends StatefulWidget {
  final String? targetType;
  final String? targetId;

  const ReportPage({
    super.key,
    this.targetType,
    this.targetId,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final TextEditingController _reason;
  late final TextEditingController _description;
  late String _targetType;
  late final TextEditingController _targetId;

  @override
  void initState() {
    super.initState();
    _reason = TextEditingController();
    _description = TextEditingController();
    _targetType = widget.targetType ?? 'document';
    _targetId = TextEditingController(text: widget.targetId ?? '');
  }

  @override
  void dispose() {
    _reason.dispose();
    _description.dispose();
    _targetId.dispose();
    super.dispose();
  }

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
    final isLocked = widget.targetId != null && widget.targetId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportViolationTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLocked) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đối tượng bị báo cáo:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_targetType == 'document'
                          ? l10n.documentType
                          : _targetType == 'place'
                              ? l10n.studyPlaceLabel
                              : _targetType == 'user'
                                  ? l10n.userType
                                  : _targetType}: ${_targetId.text}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _targetType,
                decoration: InputDecoration(labelText: l10n.type, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'document', child: Text(l10n.documentType)),
                  DropdownMenuItem(value: 'place', child: Text(l10n.studyPlaceLabel)),
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
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _reason,
              decoration: InputDecoration(
                labelText: l10n.reason,
                hintText: 'Nhập lý do báo cáo (ví dụ: vi phạm bản quyền, spam...)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: InputDecoration(
                labelText: l10n.detailedDescription,
                hintText: 'Nhập mô tả chi tiết nội dung vi phạm...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.submitReport,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
