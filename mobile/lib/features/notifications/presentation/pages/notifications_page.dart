import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../widgets/notification_detail_sheet.dart';

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

  Future<void> _markAllRead() async {
    if (!SfinityApp.notificationManager.enabled) return;
    await ApiClient.instance.patch('/notifications/read-all', {});
    _load();
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString() ?? '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationDetailSheet(notification: notification),
    );
    if (!mounted || id.isEmpty) return;
    if (notification['read'] != true) {
      setState(() {
        final index = _items.indexWhere(
          (item) => (item as Map<String, dynamic>)['id']?.toString() == id,
        );
        if (index >= 0) {
          _items[index] = {
            ...Map<String, dynamic>.from(_items[index] as Map),
            'read': true,
          };
        }
      });
      await ApiClient.instance.patch('/notifications/$id/read', {});
    }
  }

  Future<void> _deleteNotification(String id) async {
    if (!SfinityApp.notificationManager.enabled) return;
    try {
      await ApiClient.instance.delete('/notifications/$id');
      if (mounted) {
        setState(() {
          _items = _items.where((n) => (n as Map<String, dynamic>)['id']?.toString() != id).toList();
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (!SfinityApp.notificationManager.enabled) return;
    try {
      await ApiClient.instance.delete('/notifications');
      if (mounted) {
        setState(() {
          _items = [];
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  void _showDeleteAllDialog(BuildContext context, String deleteAllText, String confirmText, String deleteText, String cancelText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.delete_sweep_rounded, color: Theme.of(ctx).colorScheme.error, size: 28),
        ),
        title: Text(deleteAllText, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text(confirmText, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted(ctx), height: 1.4)),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.chipBg(ctx),
                    foregroundColor: AppColors.title(ctx),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(cancelText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteAllNotifications();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(deleteText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    _markAllRead();
                  } else if (value == 'delete_all') {
                    _showDeleteAllDialog(
                      context,
                      l10n.deleteAllNotifications,
                      l10n.deleteAllNotificationsConfirm,
                      l10n.yesDelete,
                      l10n.cancel,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        const Icon(Icons.done_all, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.markAllRead),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 20, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(l10n.deleteAllNotifications, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
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
                              final id = n['id']?.toString() ?? '';
                              return Dismissible(
                                key: Key(id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                    size: 26,
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Theme.of(ctx).colorScheme.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                                      icon: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error, size: 28),
                                      ),
                                      title: Text(l10n.deleteNotification, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                      content: Text(l10n.deleteNotificationConfirm, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted(ctx), height: 1.4)),
                                      actionsPadding: const EdgeInsets.all(24),
                                      actions: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: FilledButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: AppColors.chipBg(ctx),
                                                  foregroundColor: AppColors.title(ctx),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                ),
                                                child: Text(l10n.cancel, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: FilledButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Theme.of(ctx).colorScheme.error,
                                                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  elevation: 0,
                                                ),
                                                child: Text(l10n.yesDelete, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                },
                                onDismissed: (_) => _deleteNotification(id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: ListTile(
                                  leading: Icon(
                                    read ? Icons.mark_email_read : Icons.mark_email_unread,
                                    color: read ? Colors.grey : Theme.of(context).colorScheme.primary,
                                  ),
                                  title: Text(
                                    n['title']?.toString() ?? '',
                                    style: TextStyle(
                                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    n['body']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _openNotification(n),
                                ),
                                ),
                              );
                            },
                          ),
                        ),
        );
      },
    );
  }
}
