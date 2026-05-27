import '../../../../core/network/api_client.dart';

class AuthApiService {
  AuthApiService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> login(String email, String password) {
    return _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) {
    return _api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<Map<String, dynamic>> firebaseLogin({
    required String idToken,
    required String provider,
  }) {
    return _api.post('/auth/firebase-login', {
      'idToken': idToken,
      'provider': provider,
    });
  }

  Future<Map<String, dynamic>> getProfile() {
    return _api.get('/auth/me');
  }

  Future<Map<String, dynamic>> forgotPassword(String email) {
    return _api.post('/auth/forgot-password', {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _api.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }
}