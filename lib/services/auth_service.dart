import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName('${firstName.trim()} ${lastName.trim()}');
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'role': role,
      'registeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> signOut() => _auth.signOut();

  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => 'An account already uses that email.',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' => 'Email or password is incorrect.',
        'weak-password' => 'Use a stronger password.',
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' => 'Check your connection and try again.',
        _ => 'Authentication failed. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}
