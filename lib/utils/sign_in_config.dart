import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Utility class for Google Sign-In configuration
class SignInConfig {
  /// Returns properly configured GoogleSignIn instance
  static GoogleSignIn getGoogleSignIn() {
    return GoogleSignIn(
      // Specify scopes as needed
      scopes: [
        'email',
        'profile',
      ],
      // For Android, standard sign-in is best
      signInOption: SignInOption.standard,
      // For iOS or different platforms, you might need additional configuration
      // clientId: iOS_CLIENT_ID,
    );
  }
  
  /// Check if Google Play Services are available
  static Future<bool> checkGooglePlayServices() async {
    // This is just a basic check
    try {
      if (!Platform.isAndroid) return true; // Not relevant for non-Android platforms
      
      // A real check would connect to Google Play Services
      // This is just a placeholder that always returns true
      // In a real app, you'd use a plugin to check or handle the error when signing in
      return true;
    } catch (e) {
      debugPrint('Error checking Google Play Services: $e');
      return false;
    }
  }
  
  /// Format Google sign-in error message for user display
  static String formatSignInError(dynamic error) {
    final errorMessage = error.toString();
    
    if (errorMessage.contains('network_error') || 
        errorMessage.contains('failed host lookup')) {
      return 'Network error, please check your connection';
    }
    
    if (errorMessage.contains('sign_in_failed') || 
        errorMessage.contains('PlatformException')) {
      return 'Sign-in failed, please check Google Play Services';
    }
    
    if (errorMessage.contains('popup_closed') || errorMessage.contains('canceled')) {
      return 'Sign-in was cancelled';
    }
    
    if (errorMessage.contains('ERROR_INVALID_CREDENTIAL')) {
      return 'Invalid credentials';
    }
    
    return 'Sign in error: $errorMessage';
  }
} 