import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  late ThemeMode _theme;

  @override
  void initState() {
    super.initState();
    _theme = SfinityApp.themeManager.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Thông báo'),
            subtitle: const Text('Nhận thông báo in-app'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          ListTile(
            title: const Text('Giao diện'),
            subtitle: Text(_getThemeName(_theme)),
            trailing: DropdownButton<ThemeMode>(
              value: _theme,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Hệ thống')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
              ],
              onChanged: (v) => _updateTheme(v ?? ThemeMode.system),
            ),
          ),
          ListTile(
            title: const Text('Thông báo in-app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.notifications),
          ),
          ListTile(
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.changePassword),
          ),
          const ListTile(
            title: Text('Ngôn ngữ'),
            subtitle: Text('Tiếng Việt'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _updateTheme(ThemeMode mode) {
    setState(() => _theme = mode);
    SfinityApp.themeManager.setThemeMode(mode);
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Hệ thống';
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
    }
  }
}
