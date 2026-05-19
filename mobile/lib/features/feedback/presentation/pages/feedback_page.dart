import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

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
    if (_message.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập ít nhất 5 ký tự')),
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
          const SnackBar(content: Text('Cảm ơn phản hồi của bạn!')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi phản hồi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Đánh giá: $_rating sao'),
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
              decoration: const InputDecoration(
                labelText: 'Nội dung phản hồi',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }
}
