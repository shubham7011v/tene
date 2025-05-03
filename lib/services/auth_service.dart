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
      
      // First check if the user is already signed in to Google
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      try {
        if (currentUser == null) {
          // Try silent sign-in first to avoid UI if possible
          currentUser = await _googleSignIn.signInSilently();
        }
      } catch (e) {
        // Continue with manual sign-in
      }
      
      // If still not signed in, try manual sign-in
      GoogleSignInAccount? googleUser = currentUser;
      if (googleUser == null) {
        try {
          googleUser = await _googleSignIn.signIn();
        } catch (signInError) {
          
          // Format the error message for better debugging
          final errorMsg = SignInConfig.formatSignInError(signInError);
          
          // Check if the error is about the Play Services
          if (signInError.toString().contains('PlatformException') && 
              signInError.toString().contains('sign_in_failed')) {
            return null;
          }
          
          rethrow;
        }
      }
      
      // If sign-in was cancelled by user, return null
      if (googleUser == null) {
        return null;
      }

      
      try {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final userCredential = await _auth.signInWithCredential(credential);
        
        // Create or update user profile in Firestore
        await createOrUpdateUserProfile(
          displayName: googleUser.displayName,
          photoURL: googleUser.photoUrl,
          email: googleUser.email,
        );
        
        return userCredential;
      } catch (authError) {
        rethrow;
      }
    } catch (e) {
      // For debugging, print more information about the error
      if (e is Exception) {
      }
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