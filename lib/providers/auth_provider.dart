import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required FirestoreService firestoreService,
  }) : _authService = authService,
       _firestoreService = firestoreService {
    _authSubscription = _authService.authStateChanges().listen(
      (user) {
        unawaited(_handleAuthStateChanged(user));
      },
      onError: (Object error) {
        _handleAuthStreamError(error);
      },
    );
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;

  StreamSubscription<User?>? _authSubscription;
  final Completer<void> _initCompleter = Completer<void>();

  User? _user;
  bool _isBusy = false;
  bool _isInitialized = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isBusy => _isBusy;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _user != null;

  String get displayName {
    final currentUser = _user;
    if (currentUser == null) {
      return 'Challenger';
    }

    if (currentUser.displayName?.trim().isNotEmpty ?? false) {
      return currentUser.displayName!.trim();
    }

    if (currentUser.email?.trim().isNotEmpty ?? false) {
      return currentUser.email!.trim().split('@').first;
    }

    return currentUser.isAnonymous ? 'Guest' : 'Challenger';
  }

  Future<void> waitUntilInitialized() {
    return _initCompleter.future;
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _runAuthAction(() async {
      await _authService.signInWithEmail(email: email, password: password);
    });
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _runAuthAction(() async {
      await _authService.registerWithEmail(email: email, password: password);
    });
  }

  Future<bool> signInWithGoogle() {
    return _runAuthAction(() async {
      await _authService.signInWithGoogle();
    });
  }

  Future<bool> continueAsGuest() {
    return _runAuthAction(() async {
      await _authService.signInAnonymously();
    });
  }

  Future<bool> sendPasswordResetEmail({required String email}) {
    return _runAuthAction(() async {
      await _authService.sendPasswordResetEmail(email: email);
    });
  }

  Future<bool> signOut() async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    _user = user;
    _errorMessage = null;

    if (user != null) {
      try {
        await _firestoreService.ensureUserDocument(user);
      } catch (error) {
        final readableError = _readableError(error);
        final isCloudSyncOnlyIssue = readableError.toLowerCase().contains(
          'cloud sync is blocked',
        );
        if (!isCloudSyncOnlyIssue) {
          _errorMessage = readableError;
        }
      }
    }

    _isInitialized = true;
    _completeInitializationIfNeeded();
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    if (_isBusy) {
      return false;
    }

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _handleAuthStreamError(Object error) {
    if (_authService.isKnownPigeonCastIssue(error)) {
      unawaited(_recoverFromKnownCastIssue());
      return;
    }

    _errorMessage = _readableError(error);
    _isInitialized = true;
    _completeInitializationIfNeeded();
    notifyListeners();
  }

  Future<void> _recoverFromKnownCastIssue() async {
    final immediateUser = _authService.currentUser;
    if (immediateUser != null) {
      await _handleAuthStateChanged(immediateUser);
      return;
    }

    for (var attempt = 0; attempt < 4; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final recoveredUser = _authService.currentUser;
      if (recoveredUser != null) {
        await _handleAuthStateChanged(recoveredUser);
        return;
      }
    }

    _errorMessage =
        'Authentication plugin bridge is out of sync. '
        'Stop the app, run "flutter clean", uninstall the app from emulator/device, '
        'then run "flutter pub get" and launch again.';
    _isInitialized = true;
    _completeInitializationIfNeeded();
    notifyListeners();
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    final lowered = message.toLowerCase();
    if (_authService.isKnownPigeonCastIssue(error) ||
        (lowered.contains('list<object?>') &&
            (lowered.contains('pigeonuserdetails') ||
                lowered.contains('pigeonuserinfo')))) {
      return 'Authentication plugin bridge is out of sync. '
          'Stop the app, run "flutter clean", uninstall the app from emulator/device, '
          'then run "flutter pub get" and launch again.';
    }
    if (lowered.contains('permission-denied')) {
      return 'Cloud sync is blocked by Firestore rules for this user session.';
    }
    return message;
  }

  void _completeInitializationIfNeeded() {
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
