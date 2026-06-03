import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import 'auth_repository.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._repo);

  final AuthRepository _repo;
  Map<String, dynamic>? user;
  bool isLoading = true;

  bool get isAuthenticated => user != null;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      final token = await _repo.getToken();
      if (token != null) {
        ApiClient.instance.setToken(token);
        try {
          // Thử tải thông tin trực tiếp từ Server qua Internet
          user = await _repo.getProfile();
        } catch (e) {
          print('Mất kết nối mạng, tải thông tin profile từ SQLite local: $e');
          // Offline -> Sử dụng thông tin người dùng được lưu trữ cục bộ trong SQLite
          user = await _repo.getCachedProfile();
        }
      }
    } catch (_) {
      await _repo.clearSession();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _repo.login(email, password);
    user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    final result = await _repo.loginWithGoogle();
    user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> loginWithFacebook() async {
    final result = await _repo.loginWithFacebook();
    user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> register(String email, String password, String name) async {
    await _repo.register(email, password, name);
    await _repo.clearSession();
  }

  Future<void> logout() async {
    await _repo.clearSession();
    user = null;
    notifyListeners();
  }

  void setUser(Map<String, dynamic> data) {
    user = data;
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    await _repo.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _repo.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final result = await _repo.updateProfile(data);
    return result;
  }
}