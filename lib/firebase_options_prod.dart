import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultProdFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError('DefaultProdFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCE2SEEQSH0VM9uEcVHCTb8XjcgxbKcXys',
    appId: '1:299716528703:web:c1d880486c58153223468a',
    messagingSenderId: '299716528703',
    projectId: 'tene-emotions-prod',
    authDomain: 'tene-emotions-prod.firebaseapp.com',
    storageBucket: 'tene-emotions-prod.firebasestorage.app',
  );

  // Production Firebase configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDVRhzyVJgX4uOp3cv5MyxaERhwliispW8',
    appId: '1:299716528703:android:c01d30a37e939d9123468a',
    messagingSenderId: '299716528703',
    projectId: 'tene-emotions-prod',
    storageBucket: 'tene-emotions-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDeK3MksqO8uMSVciMDG1NjOXeTD0LouDU',
    appId: '1:299716528703:ios:fead2262d8e9fad923468a',
    messagingSenderId: '299716528703',
    projectId: 'tene-emotions-prod',
    storageBucket: 'tene-emotions-prod.firebasestorage.app',
    iosBundleId: 'com.teneapp.production',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDeK3MksqO8uMSVciMDG1NjOXeTD0LouDU',
    appId: '1:299716528703:ios:fead2262d8e9fad923468a',
    messagingSenderId: '299716528703',
    projectId: 'tene-emotions-prod',
    storageBucket: 'tene-emotions-prod.firebasestorage.app',
    iosBundleId: 'com.teneapp.production',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCE2SEEQSH0VM9uEcVHCTb8XjcgxbKcXys',
    appId: '1:299716528703:web:0e9096fd0a8f2ee123468a',
    messagingSenderId: '299716528703',
    projectId: 'tene-emotions-prod',
    authDomain: 'tene-emotions-prod.firebaseapp.com',
    storageBucket: 'tene-emotions-prod.firebasestorage.app',
  );
}
