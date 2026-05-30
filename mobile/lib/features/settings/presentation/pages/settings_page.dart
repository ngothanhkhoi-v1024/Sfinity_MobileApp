import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _theme;

  @override
  void initState() {
    super.initState();
    _theme = SfinityApp.themeManager.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final locale = SfinityApp.localeManager.locale;
    final notificationsEnabled = SfinityApp.notificationManager.enabled;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.notifications),
            subtitle: Text(notificationsEnabled ? l10n.receiveInAppNotifications : l10n.notificationsDisabled),
            value: notificationsEnabled,
            onChanged: (v) async {
              await SfinityApp.notificationManager.setEnabled(v);
              if (mounted) setState(() {});
            },
          ),
          ListTile(
            title: Text(l10n.inAppNotificationSettings),
            subtitle: Text(l10n.notificationSettingsDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.notificationSettings),
          ),
          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(_getThemeName(context, _theme)),
            trailing: DropdownButton<ThemeMode>(
              value: _theme,
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
              ],
              onChanged: (v) => _updateTheme(v ?? ThemeMode.system),
            ),
          ),
          ListTile(
            title: Text(l10n.notificationsInApp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.notifications),
          ),
          ListTile(
            title: Text(l10n.changePassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.changePassword),
          ),
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(_getLocaleName(context, locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push(RouteNames.languageSettings);
            },
          ),
        ],
      ),
    );
  }

  void _updateTheme(ThemeMode mode) {
    setState(() => _theme = mode);
    SfinityApp.themeManager.setThemeMode(mode);
  }

  String _getThemeName(BuildContext context, ThemeMode mode) {
    final l10n = context.l10n;
    switch (mode) {
      case ThemeMode.system:
        return l10n.system;
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
    }
  }

  String _getLocaleName(BuildContext context, Locale locale) {
    final l10n = context.l10n;
    switch (locale.languageCode) {
      case 'en':
        return l10n.english;
      case 'vi':
      default:
        return l10n.vietnamese;
    }
  }
}
