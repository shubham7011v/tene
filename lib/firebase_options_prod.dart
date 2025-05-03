import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps in the production environment.
///
/// Example:
/// ```dart
/// import 'firebase_options_prod.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultProdFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultProdFirebaseOptions {
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
          'DefaultProdFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultProdFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultProdFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Production Firebase configuration - Replace these with your actual Firebase production configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyProdProdProdProdProdProdProdProdProdProdProd',
    appId: '1:987654321098:web:abcdef0987654321',
    messagingSenderId: '987654321098',
    projectId: 'tene-app-prod',
    authDomain: 'tene-app-prod.firebaseapp.com',
    storageBucket: 'tene-app-prod.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyProdProdProdProdProdProdProdProdProdProd',
    appId: '1:987654321098:android:abcdef0987654321',
    messagingSenderId: '987654321098',
    projectId: 'tene-app-prod',
    storageBucket: 'tene-app-prod.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyProdProdProdProdProdProdProdProdProdProd',
    appId: '1:987654321098:ios:abcdef0987654321',
    messagingSenderId: '987654321098',
    projectId: 'tene-app-prod',
    storageBucket: 'tene-app-prod.appspot.com',
    iosClientId: '987654321098-abcdef0987654321.apps.googleusercontent.com',
    iosBundleId: 'com.example.tene',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyProdProdProdProdProdProdProdProdProdProd',
    appId: '1:987654321098:macos:abcdef0987654321',
    messagingSenderId: '987654321098',
    projectId: 'tene-app-prod',
    storageBucket: 'tene-app-prod.appspot.com',
    iosClientId: '987654321098-abcdef0987654321.apps.googleusercontent.com',
    iosBundleId: 'com.example.tene',
  );
} 