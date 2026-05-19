import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class AuthRepository {
  static const _tokenKey = 'access_token';

  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    final data = await _api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _api.get('/auth/me');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _api.setToken(token);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _api.setToken(null);
  }
}
