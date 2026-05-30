import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager extends ChangeNotifier {
  static const String _localeKey = 'app_locale_code';

  Locale _locale = const Locale('vi');
  late SharedPreferences _prefs;

  Locale get locale => _locale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLocale();
  }

  void _loadLocale() {
    final code = _prefs.getString(_localeKey) ?? 'vi';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> setVietnamese() => setLocale(const Locale('vi'));

  Future<void> setEnglish() => setLocale(const Locale('en'));
}
