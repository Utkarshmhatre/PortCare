import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Get user profile from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (userDoc.exists) {
          final appUser = AppUser.fromMap(userDoc.data()!);
          return AuthResult.success(appUser);
        } else {
          // User document doesn't exist, needs profile setup
          return AuthResult.needsProfileSetup(result.user!);
        }
      }

      return AuthResult.failure('Sign in failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Send email verification
        await result.user!.sendEmailVerification();
        return AuthResult.needsEmailVerification(result.user!);
      }

      return AuthResult.failure('Sign up failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return AuthResult.failure('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      if (result.user != null) {
        // Check if user profile exists in Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (userDoc.exists) {
          final appUser = AppUser.fromMap(userDoc.data()!);
          return AuthResult.success(appUser);
        } else {
          // Create a basic user profile from Google data
          final appUser = AppUser(
            uid: result.user!.uid,
            email: result.user!.email!,
            name: result.user!.displayName ?? 'Google User',
            phone: result.user!.phoneNumber,
            dateOfBirth: null,
            gender: null,
            profileCreatedAt: DateTime.now(),
            consent: const UserConsent(
              termsOfService: true, // Assume accepted for Google sign-in
              healthDataSharing: false,
            ),
            role: 'patient',
          );

          // Save to Firestore
          await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .set(appUser.toMap());

          // Return success with the created user profile
          return AuthResult.success(appUser);
        }
      }

      return AuthResult.failure('Google sign-in failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // Verify phone number with SMS code
  Future<AuthResult> verifyPhoneNumberWithCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      if (result.user != null) {
        // Check if user profile exists
        final userDoc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (userDoc.exists) {
          final appUser = AppUser.fromMap(userDoc.data()!);
          return AuthResult.success(appUser);
        } else {
          return AuthResult.needsProfileSetup(result.user!);
        }
      }

      return AuthResult.failure('Phone verification failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Create user profile in Firestore
  Future<AuthResult> createUserProfile({
    required String uid,
    required String name,
    required String email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    required UserConsent consent,
  }) async {
    try {
      final appUser = AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        profileCreatedAt: DateTime.now(),
        consent: consent,
      );

      await _firestore.collection('users').doc(uid).set(appUser.toMap());
      return AuthResult.success(appUser);
    } catch (e) {
      return AuthResult.failure('Failed to create profile: ${e.toString()}');
    }
  }

  // Get user profile from Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete Firebase Auth user
        await user.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Helper method to get user-friendly error messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

class AuthResult {
  final AuthResultType type;
  final AppUser? user;
  final User? firebaseUser;
  final String? error;

  AuthResult._(this.type, {this.user, this.firebaseUser, this.error});

  factory AuthResult.success(AppUser user) =>
      AuthResult._(AuthResultType.success, user: user);

  factory AuthResult.needsEmailVerification(User firebaseUser) => AuthResult._(
    AuthResultType.needsEmailVerification,
    firebaseUser: firebaseUser,
  );

  factory AuthResult.needsProfileSetup(User firebaseUser) => AuthResult._(
    AuthResultType.needsProfileSetup,
    firebaseUser: firebaseUser,
  );

  factory AuthResult.failure(String error) =>
      AuthResult._(AuthResultType.failure, error: error);

  bool get isSuccess => type == AuthResultType.success;
  bool get needsEmailVerification =>
      type == AuthResultType.needsEmailVerification;
  bool get needsProfileSetup => type == AuthResultType.needsProfileSetup;
  bool get isFailure => type == AuthResultType.failure;
}

enum AuthResultType {
  success,
  needsEmailVerification,
  needsProfileSetup,
  failure,
}
