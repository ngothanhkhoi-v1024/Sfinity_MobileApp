import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
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
    if (!SfinityApp.notificationManager.enabled) {
      setState(() {
        _items = [];
        _loading = false;
        _error = null;
      });
      return;
    }

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
    if (!SfinityApp.notificationManager.enabled) return;
    await ApiClient.instance.patch('/notifications/$id/read', {});
    _load();
  }

  Future<void> _markAllRead() async {
    if (!SfinityApp.notificationManager.enabled) return;
    await ApiClient.instance.patch('/notifications/read-all', {});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: SfinityApp.notificationManager,
      builder: (context, child) {
        final notificationsEnabled = SfinityApp.notificationManager.enabled;

        if (!notificationsEnabled) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.notifications)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(l10n.notificationsDisabled, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(l10n.notificationsDisabledDescription, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push(RouteNames.notificationSettings),
                      child: Text(l10n.enableNotifications),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
      },
    );
  }
}
