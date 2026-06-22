import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialAuthService {
  bool _googleInitialized = false;

  Future<void> ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<String> signInWithGoogle() async {
    await ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final googleAuth = account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google login không trả về idToken.');
    }
    return idToken;
  }

  Future<String> signInWithFacebook() async {
    // Đăng xuất trước để tránh cache token cũ
    await FacebookAuth.instance.logOut();

    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
      loginBehavior: LoginBehavior.webOnly,
    );

    if (result.status == LoginStatus.success) {
      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Facebook login không trả về access token.');
      }
      return accessToken;
    } else if (result.status == LoginStatus.cancelled) {
      throw Exception('Người dùng đã hủy đăng nhập Facebook.');
    } else {
      throw Exception('Đăng nhập Facebook thất bại: ${result.message}');
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}