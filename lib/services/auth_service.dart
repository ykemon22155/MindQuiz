import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Returns the currently signed-in [User] if Firebase has a persisted
  /// session (e.g. from a previous launch), otherwise `null`.
  Future<User?> restoreSessionIfPossible() async {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    }
  }
}