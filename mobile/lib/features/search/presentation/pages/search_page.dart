import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    if (_query.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/document', query: {
        'search': _query.text.trim(),
        'publishedOnly': 'true',
      });
      setState(() => _results = res['items'] as List? ?? []);
    } on DioException catch (_) {
      setState(() => _results = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _search, icon: const Icon(Icons.search)),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) {
              final item = _results[i] as Map<String, dynamic>;
              return ListTile(
                title: Text(item['title']?.toString() ?? ''),
                onTap: () => context.push('/document/${item['id']}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
