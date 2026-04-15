import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_readableAuthError(error));
    }
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_readableAuthError(error));
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      throw Exception(_readableAuthError(error));
    } catch (error) {
      final recoveredUser = await _waitForSignedInUser();
      if (recoveredUser != null) {
        return;
      }

      if (isKnownPigeonCastIssue(error)) {
        throw Exception(
          'Guest sign-in hit a Firebase plugin mismatch. '
          'Stop the app, run "flutter clean", uninstall the app from emulator/device, '
          'then run "flutter pub get" and launch again.',
        );
      }

      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception(
          'Google sign-in did not return valid credentials. Please try again.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw Exception(_readableAuthError(error));
    } catch (error) {
      final recoveredUser = await _waitForSignedInUser();
      if (recoveredUser != null) {
        return;
      }

      if (isKnownPigeonCastIssue(error)) {
        throw Exception(
          'Google sign-in hit a Firebase plugin mismatch. '
          'Stop the app, run "flutter clean", uninstall the app from emulator/device, '
          'then run "flutter pub get" and launch again.',
        );
      }

      if (error is PlatformException) {
        throw Exception(_readableGoogleSignInError(error));
      }

      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        // Do not expose whether an account exists for this email.
        return;
      }
      throw Exception(_readablePasswordResetError(error));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore if the current user session is not Google-authenticated.
    }
  }

  String _readableAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  bool isKnownPigeonCastIssue(Object error) {
    final message = error.toString();
    return message.contains("List<Object?>") &&
        (message.contains('PigeonUserDetails') ||
            message.contains('PigeonUserInfo'));
  }

  String _readableGoogleSignInError(PlatformException error) {
    final rawMessage =
        '${error.code} ${error.message ?? ''} ${error.details ?? ''}';
    final lowered = rawMessage.toLowerCase();

    if (error.code == 'sign_in_canceled') {
      return 'Google sign-in was cancelled.';
    }

    if (lowered.contains('apiexception: 10')) {
      return 'Google sign-in is not configured correctly for Android (ApiException: 10). '
          'In Firebase Console, add SHA-1 and SHA-256 for package com.flaggenius.app, '
          'download a fresh google-services.json, replace android/app/google-services.json, '
          'then run flutter clean and reinstall the app.';
    }

    if (lowered.contains('network')) {
      return 'Google sign-in failed due to a network issue. Check your connection and try again.';
    }

    final cleaned = (error.message ?? 'Google sign-in failed.').trim();
    if (cleaned.isEmpty) {
      return 'Google sign-in failed. Please try again.';
    }

    return cleaned;
  }

  String _readablePasswordResetError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address to receive a reset link.';
      case 'too-many-requests':
        return 'Too many reset attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Could not send reset email right now. Please try again.';
    }
  }

  Future<User?> _waitForSignedInUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    try {
      return await _firebaseAuth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      return _firebaseAuth.currentUser;
    }
  }
}
