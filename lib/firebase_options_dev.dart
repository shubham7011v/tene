import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError('DefaultDevFirebaseOptions are not supported for this platform.');
    }
  }

  // Development Firebase configuration - Replace these with your actual Firebase development configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDXRoQ_XjPfMlaSAuOxqiZdAJZ_ITWKq-U',
    appId: '1:148139223467:android:951f7945060384cffd4aee',
    messagingSenderId: '148139223467',
    projectId: 'tene-emotions',
    authDomain: 'tene-emotions.firebaseapp.com',
    storageBucket: 'tene-emotions.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXRoQ_XjPfMlaSAuOxqiZdAJZ_ITWKq-U',
    appId: '1:148139223467:android:951f7945060384cffd4aee',
    messagingSenderId: '148139223467',
    projectId: 'tene-emotions',
    storageBucket: 'tene-emotions.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDXRoQ_XjPfMlaSAuOxqiZdAJZ_ITWKq-U',
    appId: '1:148139223467:android:951f7945060384cffd4aee',
    messagingSenderId: '148139223467',
    projectId: 'tene-emotions',
    storageBucket: 'tene-emotions.firebasestorage.app',
    iosClientId: '148139223467-kvuc5kamhd6are6i2u4ood3gocgufvfc.apps.googleusercontent.com',
    iosBundleId: 'com.example.tene',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDXRoQ_XjPfMlaSAuOxqiZdAJZ_ITWKq-U',
    appId: '1:148139223467:android:951f7945060384cffd4aee',
    messagingSenderId: '148139223467',
    projectId: 'tene-emotions',
    storageBucket: 'tene-emotions.firebasestorage.app',
    iosClientId: '148139223467-kvuc5kamhd6are6i2u4ood3gocgufvfc.apps.googleusercontent.com',
    iosBundleId: 'com.example.tene',
  );
}
