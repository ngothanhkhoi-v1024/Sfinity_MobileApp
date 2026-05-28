abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> loginWithGoogle();
  Future<Map<String, dynamic>> loginWithFacebook();
  Future<Map<String, dynamic>> register(String email, String password, String name);
  Future<Map<String, dynamic>> getProfile();
  Future<String?> getToken();
  Future<Map<String, dynamic>?> getCachedProfile();
  Future<void> clearSession();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}