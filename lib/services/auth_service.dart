import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get current user ID or empty string
  String get currentUserId => _auth.currentUser?.uid ?? '';
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Phone verification IDs
  String? _verificationId;
  int? _resendToken;
  
  /// Request phone verification code
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
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }
  
  /// Sign in with credential
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }
  
  /// Verify phone number with OTP code
  Future<UserCredential> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      throw FirebaseAuthException(
        code: 'invalid-verification-id',
        message: 'Verification ID is missing. Please request a new code.',
      );
    }
    
    // Create credential
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    
    // Sign in with credential
    return await _auth.signInWithCredential(credential);
  }
  
  /// Create or update user profile in Firestore
  Future<void> createOrUpdateUserProfile({
    required String phoneNumber,
    String? displayName,
    String? photoURL,
  }) async {
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    
    // Reference to users collection
    final userRef = _firestore.collection('users').doc(currentUserId);
    
    // Check if user document exists
    final doc = await userRef.get();
    
    if (doc.exists) {
      // Update existing user
      await userRef.update({
        'phoneNumber': phoneNumber,
        'lastUpdated': FieldValue.serverTimestamp(),
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      });
    } else {
      // Create new user
      await userRef.set({
        'phoneNumber': phoneNumber,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'displayName': displayName ?? '',
        'photoURL': photoURL ?? '',
      });
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
} 