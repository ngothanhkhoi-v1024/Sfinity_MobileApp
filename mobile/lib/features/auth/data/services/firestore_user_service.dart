import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreUserService {
  Future<void> syncUser(User firebaseUser, {String? displayName, String? provider}) async {
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
