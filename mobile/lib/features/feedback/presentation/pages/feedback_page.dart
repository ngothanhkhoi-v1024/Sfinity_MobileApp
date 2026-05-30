import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _message = TextEditingController();
  int _rating = 5;
  bool _loading = false;

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_message.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterAtLeast5Characters)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/feedback', {
        'message': _message.text.trim(),
        'rating': _rating,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.thanksForYourFeedback)),
        );
        _message.clear();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendFeedback)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.ratingLabel(_rating)),
            Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: _rating.toDouble(),
              label: '$_rating',
              onChanged: (v) => setState(() => _rating = v.round()),
            ),
            TextField(
              controller: _message,
              decoration: InputDecoration(
                labelText: l10n.feedbackContent,
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(l10n.submit),
            ),
          ],
        ),
      ),
    );
  }
}
