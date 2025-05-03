import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps in the development environment.
///
/// Example:
/// ```dart
/// import 'firebase_options_dev.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultDevFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultDevFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultDevFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultDevFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultDevFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Development Firebase configuration - Replace these with your actual Firebase development configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDevDevDevDevDevDevDevDevDevDevDevDevDev',
    appId: '1:123456789012:web:abcdef1234567890dev',
    messagingSenderId: '123456789012',
    projectId: 'tene-app-dev',
    authDomain: 'tene-app-dev.firebaseapp.com',
    storageBucket: 'tene-app-dev.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDevDevDevDevDevDevDevDevDevDevDevDevDev',
    appId: '1:123456789012:android:abcdef1234567890dev',
    messagingSenderId: '123456789012',
    projectId: 'tene-app-dev',
    storageBucket: 'tene-app-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDevDevDevDevDevDevDevDevDevDevDevDevDev',
    appId: '1:123456789012:ios:abcdef1234567890dev',
    messagingSenderId: '123456789012',
    projectId: 'tene-app-dev',
    storageBucket: 'tene-app-dev.appspot.com',
    iosClientId: '123456789012-abcdef1234567890dev.apps.googleusercontent.com',
    iosBundleId: 'com.example.tene.dev',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDevDevDevDevDevDevDevDevDevDevDevDevDev',
    appId: '1:123456789012:macos:abcdef1234567890dev',
    messagingSenderId: '123456789012',
    projectId: 'tene-app-dev',
    storageBucket: 'tene-app-dev.appspot.com',
    iosClientId: '123456789012-abcdef1234567890dev.apps.googleusercontent.com',
    iosBundleId: 'com.example.tene.dev',
  );
} 