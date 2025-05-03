import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tene/utils/sign_in_config.dart';

/// Service locator to provide singleton instances of Firebase services
class ServiceLocator {
  ServiceLocator._();
  
  // Singleton instance
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;
  
  // Firebase instances
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  GoogleSignIn? _googleSignIn;
  bool _initialized = false;
  
  /// Initialize the service locator
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Get existing app or wait for initialization in main.dart
    FirebaseApp? app;
    while (app == null) {
      if (Firebase.apps.isNotEmpty) {
        app = Firebase.apps.first;
        break;
      }
      // Small delay to give main.dart time to initialize Firebase
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _googleSignIn = SignInConfig.getGoogleSignIn();
    _initialized = true;
  }
  
  /// Get the Firebase Auth instance
  FirebaseAuth get auth {
    if (!_initialized) {
      // If called without initialization, fall back to default instance
      // but log a warning
      return FirebaseAuth.instance;
    }
    return _auth!;
  }
  
  /// Get the Firestore instance
  FirebaseFirestore get firestore {
    if (!_initialized) {
      return FirebaseFirestore.instance;
    }
    return _firestore!;
  }
  
  /// Get the Google Sign In instance
  GoogleSignIn get googleSignIn {
    if (!_initialized) {
      return SignInConfig.getGoogleSignIn();
    }
    return _googleSignIn!;
  }
  
  /// Check if Firebase is initialized
  bool get isInitialized => _initialized;
} 