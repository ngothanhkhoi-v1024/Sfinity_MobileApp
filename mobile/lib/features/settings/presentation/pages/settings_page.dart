import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  ThemeMode _theme = ThemeMode.system;

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
            subtitle: Text(_theme.name),
            trailing: DropdownButton<ThemeMode>(
              value: _theme,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Hệ thống')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
              ],
              onChanged: (v) => setState(() => _theme = v ?? ThemeMode.system),
            ),
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
}
