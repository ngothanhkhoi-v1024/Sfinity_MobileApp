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

  // Tạm thời vô hiệu hóa Facebook Login
  Future<String> signInWithFacebook() async {
    throw UnimplementedError(
      'Facebook login đã được tạm thời vô hiệu hóa',
    );
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}