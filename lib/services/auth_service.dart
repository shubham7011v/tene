import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tene/services/service_locator.dart';

class AuthService {
  // Get Firebase instances from the ServiceLocator
  FirebaseAuth get _auth => ServiceLocator.instance.auth;
  FirebaseFirestore get _firestore => ServiceLocator.instance.firestore;
  GoogleSignIn get _googleSignIn => ServiceLocator.instance.googleSignIn;

  // Constants for SharedPreferences
  static const String isGoogleLinkedKey = 'is_google_linked';
  static const String linkedUserIdKey = 'linked_user_id';
  static const String linkedPhoneKey = 'linked_phone';
  static const String isPhoneLinkedKey = 'is_phone_linked';
  static const String linkedPhoneNumberKey = 'linked_phone_number';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID or empty string
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if Google account is linked to this device
  Future<bool> isGoogleLinked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isGoogleLinkedKey) ?? false;
  }

  /// Get the linked user ID if any
  Future<String?> getLinkedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(linkedUserIdKey);
  }

  /// Get the linked phone number if any
  Future<String?> getLinkedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(linkedPhoneKey);
  }

  /// Check if phone is linked to this account
  Future<bool> isPhoneLinked() async {
    // First check if user has phone number
    if (currentUser?.phoneNumber != null) {
      return true;
    }

    // Then check SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isPhoneLinkedKey) ?? false;
  }

  /// Set phone as linked
  Future<void> setPhoneLinked(String userId, String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isPhoneLinkedKey, true);
    await prefs.setString(linkedPhoneNumberKey, phoneNumber);

    // Also store in Firestore
    await _firestore.collection('users').doc(userId).update({
      'isPhoneLinked': true,
      'phoneNumber': phoneNumber,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Set Google account as linked
  Future<void> setGoogleLinked(String userId, String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isGoogleLinkedKey, true);
    await prefs.setString(linkedUserIdKey, userId);
    await prefs.setString(linkedPhoneKey, phoneNumber);

    // Also store this info in Firestore for multi-device access
    await _firestore.collection('users').doc(userId).update({
      'isGoogleLinked': true,
      'linkedPhone': phoneNumber,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

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

  /// Link current user with Google credentials
  Future<UserCredential?> linkWithGoogle() async {
    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    try {
      // Print debugging info
      print('Starting Google account linking process');

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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the Google credential with current user
      final userCredential = await currentUser!.linkWithCredential(credential);

      // Store phone number from current auth
      final phoneNumber = currentUser?.phoneNumber;
      if (phoneNumber != null) {
        // Mark as linked in both local storage and Firestore
        await setGoogleLinked(currentUser!.uid, phoneNumber);
      }

      return userCredential;
    } catch (e) {
      print('Error linking with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if we have a linked account first
      final String? linkedUserId = await getLinkedUserId();

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
          'phoneNumber': currentUser?.phoneNumber,
          'isGoogleLinked': false,
          'isPhoneLinked': currentUser?.phoneNumber != null,
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
