import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/network/api_client.dart';
import '../services/auth_api_service.dart';
import '../services/auth_local_database.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_user_service.dart';
import '../services/social_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApiService apiService,
    required AuthLocalDatabase localDatabase,
    required FirebaseAuthService firebaseAuthService,
    required SocialAuthService socialAuthService,
    required FirestoreUserService firestoreUserService,
  })  : _apiService = apiService,
        _localDatabase = localDatabase,
        _firebaseAuthService = firebaseAuthService,
        _socialAuthService = socialAuthService,
        _firestoreUserService = firestoreUserService;

  final AuthApiService _apiService;
  final AuthLocalDatabase _localDatabase;
  final FirebaseAuthService _firebaseAuthService;
  final SocialAuthService _socialAuthService;
  final FirestoreUserService _firestoreUserService;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _apiService.login(email, password);

    try {
      final credential = await _firebaseAuthService.signInWithEmail(email, password);
      if (credential.user != null) {
        await _firestoreUserService.syncUser(
          credential.user!,
          displayName: data['user']?['name'] as String?,
          provider: 'password',
        );
      }
    } catch (e) {
      print('Firebase Auth login error: $e');
      if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
        try {
          final credential = await _firebaseAuthService.createUserWithEmail(email, password);
          final userMap = data['user'] as Map<String, dynamic>?;
          if (userMap != null && userMap['name'] != null) {
            await credential.user?.updateDisplayName(userMap['name'] as String);
          }
          if (credential.user != null) {
            await _firestoreUserService.syncUser(
              credential.user!,
              displayName: userMap?['name'] as String?,
              provider: 'password',
            );
          }
        } catch (createErr) {
          print('Failed to auto-create user on Firebase during login: $createErr');
        }
      }
    }

    await _saveSession(data);
    return data;
  }

  @override
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    String? uid;

    try {
      final credential = await _firebaseAuthService.createUserWithEmail(email, password);
      await credential.user?.updateDisplayName(name);
      await credential.user?.sendEmailVerification();
      uid = credential.user?.uid;
    } catch (e) {
      print('Firebase Auth register error: $e');
    }

    final data = await _apiService.register(email, password, name, uid: uid);

    await _saveSession(data);
    return data;
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle() async {
    final idToken = await _socialAuthService.signInWithGoogle();

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _firebaseAuthService.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _firestoreUserService.syncUser(
        userCredential.user!,
        provider: 'google.com',
      );
    }

    return _loginWithFirebase('google.com');
  }

  @override
  Future<Map<String, dynamic>> loginWithFacebook() async {
    final accessToken = await _socialAuthService.signInWithFacebook();

    final credential = FacebookAuthProvider.credential(accessToken);
    final userCredential = await _firebaseAuthService.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _firestoreUserService.syncUser(
        userCredential.user!,
        provider: 'facebook.com',
      );
    }

    return _loginWithFirebase('facebook.com');
  }

  @override
  Future<Map<String, dynamic>> getProfile() {
    return _apiService.getProfile();
  }

  @override
  Future<String?> getToken() {
    return _localDatabase.getToken();
  }

  @override
  Future<Map<String, dynamic>?> getCachedProfile() {
    return _localDatabase.getCachedProfile();
  }

  @override
  Future<void> clearSession() async {
    await _localDatabase.clearSession();
    ApiClient.instance.setToken(null);
    await _firebaseAuthService.signOut();
    await _socialAuthService.signOut();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _apiService.forgotPassword(email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _apiService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  Future<Map<String, dynamic>> _loginWithFirebase(String provider) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Không lấy được Firebase ID token.');
    }
    final data = await _apiService.firebaseLogin(idToken: idToken, provider: provider);
    await _saveSession(data);
    return data;
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String;
    final userMap = data['user'] as Map<String, dynamic>? ?? {};

    await _localDatabase.saveSession(
      uid: userMap['id']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      name: userMap['name']?.toString() ?? '',
      avatar: userMap['avatar']?.toString(),
      accessToken: token,
    );

    ApiClient.instance.setToken(token);
  }
}
