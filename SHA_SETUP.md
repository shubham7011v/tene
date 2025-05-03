# SHA-1 Certificate Setup for Google Sign-In

The "sign in failed please check google play services" error is typically caused by a mismatch between the SHA-1 fingerprint in your Firebase project and the one used to sign your app. Follow these steps to fix this issue:

## 1. Get your SHA-1 Debug Certificate

### On Windows:
```
cd %USERPROFILE%\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### On macOS/Linux:
```
cd ~/.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line that starts with `SHA1:` followed by a fingerprint like `AA:BB:CC:...`

## 2. Add SHA-1 to Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`tene-emotions`)
3. Click on the gear icon (⚙️) next to "Project Overview" to open project settings
4. Select the "Android app" (`com.example.tene` for development, `com.example.tene` for production)
5. Click "Add fingerprint" under the "SHA certificate fingerprints" section
6. Enter the SHA-1 fingerprint you obtained in step 1
7. Click "Save"

## 3. Download Updated google-services.json

1. In the Firebase Console, click "Download google-services.json"
2. Replace the files at:
   - `android/app/src/dev/google-services.json` (for development)
   - `android/app/src/prod/google-services.json` (for production)

## 4. Enable Google Sign-In in Firebase

1. In the Firebase Console, go to "Authentication"
2. Click on the "Sign-in method" tab
3. Enable "Google" as a sign-in provider
4. Make sure your project's Support Email is set
5. Click "Save"

## 5. Rebuild and Run the App

```
flutter clean
flutter pub get
flutter run -t lib/main_dev.dart --flavor dev
```

## Common Issues and Fixes

1. **Multiple SHA-1 Fingerprints**: If you have multiple development environments, add the SHA-1 from each environment to Firebase.

2. **Release vs Debug**: Debug and release builds use different keystores. For release builds, get the SHA-1 from your upload keystore.

3. **emulator vs physical device**: The error could manifest differently on emulators vs physical devices. Test on both if possible.

4. **Google Play Services Version**: Ensure your device has the latest version of Google Play Services.

5. **Signing Report**: You can get all SHA fingerprints using:
   ```
   cd android
   ./gradlew signingReport
   ``` 