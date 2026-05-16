import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      print("   2a: Creating user in Auth...");
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // 2. Update display name in Auth profile
      print("   2b: Updating display name...");
      await user.updateDisplayName(displayName);

      // 3. Create user document in Firestore with robust error handling
      try {
        print("   2c: Attempting Firestore creation...");
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap())
            .timeout(const Duration(seconds: 10));
        print("   2d: Firestore document created!");
      } catch (e) {
        print('❌ Firestore Failed, but Auth is OK: $e');
        // Do NOT rethrow here for this test, so we can see if Auth worked
      }
    } on FirebaseAuthException catch (e) {
      print('🚨 FIREBASE AUTH ERROR: ${e.code}');
      if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
        throw 'ERROR: Email/Password is DISABLED in your Firebase Console. Go to Authentication > Sign-in method and enable it!';
      }
      rethrow;
    } catch (e) {
      print('🚨 UNEXPECTED ERROR: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed') {
        throw 'ERROR: Email/Password is DISABLED in your Firebase Console. Go to Authentication > Sign-in method and enable it!';
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }
}
