import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';

class ContentDetailPage extends StatefulWidget {
  const ContentDetailPage({super.key, required this.contentId});

  final String contentId;

  @override
  State<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends State<ContentDetailPage> {
  Map<String, dynamic>? _item;
  bool _loading = true;
  String? _error;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _item = await ApiClient.instance.get('/content/${widget.contentId}');
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await ApiClient.instance.delete('/favorites/${widget.contentId}');
      } else {
        await ApiClient.instance.post('/favorites/${widget.contentId}', {});
      }
      setState(() => _isFavorite = !_isFavorite);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  void _share() {
    final title = _item?['title']?.toString() ?? 'Sfinity';
    Share.share('Xem "$title" trên Sfinity');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _share),
          IconButton(
            icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_item?['title']?.toString() ?? '', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      if (_item?['category'] != null)
                        Chip(label: Text((_item!['category'] as Map)['name']?.toString() ?? '')),
                      const SizedBox(height: 16),
                      Text(_item?['body']?.toString() ?? ''),
                    ],
                  ),
                ),
    );
  }
}
