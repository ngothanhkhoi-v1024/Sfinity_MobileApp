import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreUserService {
  Future<void> syncUser(
    User firebaseUser, {
    String? displayName,
    String? provider,
    String? birthDate,
    String? gender,
    String? address,
  }) async {
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
        if (birthDate != null) 'birthDate': birthDate,
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
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

  Future<void> syncUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? birthDate,
    String? gender,
    String? address,
  }) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final Map<String, dynamic> data = {
        'displayName': displayName,
        'photoURL': photoUrl,
        'birthDate': birthDate,
        'gender': gender,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      data.removeWhere((k, v) => v == null);
      await userDocRef.set(data, SetOptions(merge: true));
      print('Firestore profile sync successful for user: $uid');
    } catch (e) {
      print('Failed to sync user profile to Firestore: $e');
    }
  }
}
