import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class AuthRepository {
  static const _tokenKey = 'access_token';

  final _api = ApiClient.instance;
  bool _googleInitialized = false;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _syncUserToFirestore(
          credential.user!,
          displayName: data['user']?['name'] as String?,
          provider: 'password',
        );
      }
    } catch (e) {
      print('Firebase Auth login error: $e');
      if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
        try {
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final userMap = data['user'] as Map<String, dynamic>?;
          if (userMap != null && userMap['name'] != null) {
            await credential.user?.updateDisplayName(userMap['name'] as String);
          }
          if (credential.user != null) {
            await _syncUserToFirestore(
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

  Future<Map<String, dynamic>> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    final account = await GoogleSignIn.instance.authenticate();
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google login khong tra ve idToken.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _syncUserToFirestore(
        userCredential.user!,
        provider: 'google.com',
      );
    }

    return _loginWithFirebase('google.com');
  }

  Future<Map<String, dynamic>> loginWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception(result.message ?? 'Facebook login that bai.');
    }

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _syncUserToFirestore(
        userCredential.user!,
        provider: 'facebook.com',
      );
    }
    return _loginWithFirebase('facebook.com');
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

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      if (credential.user != null) {
        await _syncUserToFirestore(
          credential.user!,
          displayName: name,
          provider: 'password',
        );
      }
    } catch (e) {
      print('Firebase Auth register error: $e');
    }

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

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _api.setToken(null);

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _loginWithFirebase(String provider) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Khong lay duoc Firebase ID token.');
    }

    final data = await _api.post('/auth/firebase-login', {
      'idToken': idToken,
      'provider': provider,
    });

    await _saveSession(data);
    return data;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;

    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _api.setToken(token);
  }

  Future<void> _syncUserToFirestore(User firebaseUser, {String? displayName, String? provider}) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
      final doc = await userDocRef.get();
      final Map<String, dynamic> data = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'displayName': displayName ?? firebaseUser.displayName,
        'photoURL': firebaseUser.photoURL,
        'provider': provider ?? firebaseUser.providerData.map((e) => e.providerId).join(','),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!doc.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await userDocRef.set(data, SetOptions(merge: true));
      print('Firestore sync successful for user: ${firebaseUser.uid}');
    } catch (e) {
      print('Failed to sync user profile to Firestore: $e');
    }
  }
}
