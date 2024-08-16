// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Failed to sign in: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Failed to register: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signOut();
    } catch (e) {
      print('Failed to sign out: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Failed to send password reset email: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> sendEmailVerification() async {
    _isLoading = true;
    notifyListeners();
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Failed to send verification email: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    _isLoading = true;
    notifyListeners();
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateProfile(displayName: displayName, photoURL: photoURL);
      } catch (e) {
        print('Failed to update user profile: ${e.toString()}');
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}