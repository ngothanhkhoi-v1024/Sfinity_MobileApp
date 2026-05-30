import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class NotificationManager extends ChangeNotifier {
  static const String _enabledKey = 'app_notifications_enabled';

  bool _enabled = true;
  late SharedPreferences _prefs;

  bool get enabled => _enabled;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadEnabled();
  }

  void _loadEnabled() {
    _enabled = _prefs.getBool(_enabledKey) ?? true;
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    await ApiClient.instance.patch('/auth/notification-preferences', {
      'notificationsEnabled': enabled,
    });

    _enabled = enabled;
    await _prefs.setBool(_enabledKey, enabled);
    notifyListeners();
  }

  Future<void> toggle() => setEnabled(!_enabled);
}


