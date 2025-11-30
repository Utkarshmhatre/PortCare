import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  AppUser? _user;
  String? _errorMessage;
  User? _firebaseUser;

  // Getters
  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _initializeAuthListener();
  }

  // Flag to prevent race condition when signing in
  bool _isSigningIn = false;

  void _initializeAuthListener() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      // Skip if we're in the middle of a sign-in process
      // The sign-in method will handle the state update
      if (_isSigningIn) {
        return;
      }

      if (firebaseUser != null) {
        // User is signed in, try to get profile with retry
        AppUser? appUser;
        
        // Retry a few times in case document is still being written
        for (int i = 0; i < 3; i++) {
          appUser = await _authService.getUserProfile(firebaseUser.uid);
          if (appUser != null) break;
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
        
        if (appUser != null) {
          _user = appUser;
          _firebaseUser = firebaseUser;
          _status = AuthStatus.authenticated;
        } else {
          // User exists but no profile, needs setup
          _firebaseUser = firebaseUser;
          _user = null;
          _status = AuthStatus.unauthenticated;
        }
      } else {
        // User is signed out
        _user = null;
        _firebaseUser = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isSigningIn = true;
    _setLoading();

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        _user = result.user;
        _firebaseUser = FirebaseAuth.instance.currentUser;
        _status = AuthStatus.authenticated;
        _clearError();
        notifyListeners();
        return true;
      } else if (result.needsProfileSetup) {
        _firebaseUser = result.firebaseUser;
        _status = AuthStatus.unauthenticated;
        _clearError();
        notifyListeners();
        return true; // Will redirect to profile setup
      } else {
        _setError(result.error ?? 'Sign in failed');
        return false;
      }
    } finally {
      _isSigningIn = false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading();

    final result = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.needsEmailVerification) {
      _firebaseUser = result.firebaseUser;
      _status = AuthStatus.unauthenticated;
      _clearError();
      notifyListeners();
      return true; // Will redirect to email verification
    } else {
      _setError(result.error ?? 'Sign up failed');
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isSigningIn = true;
    _setLoading();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.isSuccess) {
        _user = result.user;
        _firebaseUser = FirebaseAuth.instance.currentUser;
        _status = AuthStatus.authenticated;
        _clearError();
        notifyListeners();
        return true;
      } else if (result.needsProfileSetup) {
        _firebaseUser = result.firebaseUser;
        _status = AuthStatus.unauthenticated;
        _clearError();
        notifyListeners();
        return true; // Will redirect to profile setup
      } else {
        _setError(result.error ?? 'Google sign-in failed');
        return false;
      }
    } finally {
      _isSigningIn = false;
    }
  }

  // Check if current result needs profile setup
  bool get needsProfileSetup => _firebaseUser != null && _user == null;

  // Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(String) onError,
  }) async {
    _setLoading();

    await _authService.signInWithPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification completed (Android only)
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e) {
          onError('Auto-verification failed: ${e.toString()}');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _setError('Phone verification failed: ${e.message}');
        onError(e.message ?? 'Phone verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        _clearError();
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout
      },
    );
  }

  // Verify phone code
  Future<bool> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    _setLoading();

    final result = await _authService.verifyPhoneNumberWithCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } else if (result.needsProfileSetup) {
      _firebaseUser = result.firebaseUser;
      _status = AuthStatus.unauthenticated;
      _clearError();
      notifyListeners();
      return true; // Will redirect to profile setup
    } else {
      _setError(result.error ?? 'Phone verification failed');
      return false;
    }
  }

  // Create user profile
  Future<bool> createUserProfile({
    required String name,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    required UserConsent consent,
  }) async {
    if (_firebaseUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    _setLoading();

    final result = await _authService.createUserProfile(
      uid: _firebaseUser!.uid,
      name: name,
      email: _firebaseUser!.email ?? '',
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      consent: consent,
    );

    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } else {
      _setError(result.error ?? 'Failed to create profile');
      return false;
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    return await _authService.isEmailVerified();
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      _setError('Failed to send verification email: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _firebaseUser = null;
    _status = AuthStatus.unauthenticated;
    _clearError();
    notifyListeners();
  }

  // Delete account
  Future<bool> deleteAccount() async {
    final success = await _authService.deleteAccount();
    if (success) {
      _user = null;
      _firebaseUser = null;
      _status = AuthStatus.unauthenticated;
      _clearError();
      notifyListeners();
    }
    return success;
  }

  // Private helper methods
  void _setLoading() {
    _status = AuthStatus.loading;
    _clearError();
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
