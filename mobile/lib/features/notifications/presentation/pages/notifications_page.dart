import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../shared/widgets/error_view.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

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
      _items = await ApiClient.instance.getList('/notifications');
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    await ApiClient.instance.patch('/notifications/$id/read', {});
    _load();
  }

  Future<void> _markAllRead() async {
    await ApiClient.instance.patch('/notifications/read-all', {});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(onPressed: _markAllRead, child: Text(l10n.markAllRead)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? Center(child: Text(l10n.noNotifications))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final n = _items[i] as Map<String, dynamic>;
                          final read = n['read'] == true;
                          return ListTile(
                            leading: Icon(
                              read ? Icons.mark_email_read : Icons.mark_email_unread,
                              color: read ? Colors.grey : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(n['title']?.toString() ?? '', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(n['body']?.toString() ?? ''),
                            onTap: () => _markRead(n['id']?.toString() ?? ''),
                          );
                        },
                      ),
                    ),
    );
  }
}
