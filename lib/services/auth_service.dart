import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tene/services/service_locator.dart';

class AuthService {
  // Get Firebase instances from the ServiceLocator
  FirebaseAuth get _auth => ServiceLocator.instance.auth;
  GoogleSignIn get _googleSignIn => ServiceLocator.instance.googleSignIn;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID or empty string
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Start phone verification process
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  /// Sign in with phone verification code
  Future<UserCredential> signInWithPhoneAuthCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Clear previous sessions
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        print('Error during disconnect (ignorable): $e');
      }

      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Error during signOut (ignorable): $e');
      }

      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In returned null (user cancelled)');
        return null;
      }

      try {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        print('Got Google authentication tokens');

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        print('Signing in to Firebase with Google credential');
        final userCredential = await _auth.signInWithCredential(credential);
        print('Firebase sign-in successful');

        return userCredential;
      } catch (authError) {
        print('Firebase auth error: $authError');
        rethrow;
      }
    } catch (e) {
      print('Google sign-in process failed: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
