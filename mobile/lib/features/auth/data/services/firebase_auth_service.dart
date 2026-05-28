import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  Future<UserCredential> signInWithEmail(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmail(String email, String password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() {
    return FirebaseAuth.instance.signOut();
  }
}
