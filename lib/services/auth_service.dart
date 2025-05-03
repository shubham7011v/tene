import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tene/utils/sign_in_config.dart';
import 'package:tene/services/service_locator.dart';

class AuthService {
  // Get Firebase instances from the ServiceLocator
  FirebaseAuth get _auth => ServiceLocator.instance.auth;
  FirebaseFirestore get _firestore => ServiceLocator.instance.firestore;
  GoogleSignIn get _googleSignIn => ServiceLocator.instance.googleSignIn;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID or empty string
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Print debugging info
      print('Starting Google Sign-In process');

      // First try to disconnect any previous sessions
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

      print('Cleared previous Google Sign-In sessions');

      // Try to sign in, with proper error catching
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
        print('Google Sign-In attempt completed');
      } catch (signInError) {
        print('Google Sign-In error caught: $signInError');

        // Format the error for analysis
        final errorStr = signInError.toString().toLowerCase();

        // Handle specific error cases
        if (errorStr.contains('sign_in_required')) {
          print('Sign-in required error detected');
          rethrow;
        }

        if (errorStr.contains('network')) {
          print('Network error detected');
          throw Exception('Please check your internet connection');
        }

        if (errorStr.contains('canceled') || errorStr.contains('popup_closed')) {
          print('Sign-in was cancelled by user');
          return null;
        }

        // For any other errors, rethrow
        rethrow;
      }

      // If sign-in was cancelled by user, return null
      if (googleUser == null) {
        print('Google Sign-In returned null (user cancelled)');
        return null;
      }

      print('Google Sign-In successful for: ${googleUser.email}');

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

        // Create or update user profile in Firestore
        await createOrUpdateUserProfile(
          displayName: googleUser.displayName,
          photoURL: googleUser.photoUrl,
          email: googleUser.email,
        );

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

  /// Create or update user profile in Firestore
  Future<void> createOrUpdateUserProfile({
    String? displayName,
    String? photoURL,
    String? email,
  }) async {
    // Check if user is authenticated
    if (currentUser == null) {
      return;
    }

    try {
      // Reference to users collection
      final userRef = _firestore.collection('users').doc(currentUserId);

      // Check if user document exists
      final doc = await userRef.get();

      if (doc.exists) {
        // Update existing user
        await userRef.update({
          'displayName': displayName,
          'photoURL': photoURL,
          'email': email,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user
        await userRef.set({
          'userId': currentUserId,
          'displayName': displayName,
          'photoURL': photoURL,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Continue without throwing - profile update is non-critical
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
