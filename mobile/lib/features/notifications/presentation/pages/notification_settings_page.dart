import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notificationsEnabled = SfinityApp.notificationManager.enabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inAppNotificationSettings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.notifications),
            subtitle: Text(notificationsEnabled ? l10n.receiveInAppNotifications : l10n.notificationsDisabled),
            value: notificationsEnabled,
            onChanged: (v) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await SfinityApp.notificationManager.setEnabled(v);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
              if (mounted) setState(() {});
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              l10n.notificationSettingsDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
