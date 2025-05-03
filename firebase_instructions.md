# Firebase Project Setup Instructions

This document provides instructions for setting up the Firebase projects for both development and production environments.

## Development Environment (tene-emotions)

### Android Setup
1. Go to the [Firebase Console](https://console.firebase.google.com/project/tene-emotions/overview)
2. Navigate to Project Settings > Add app > Android
3. Enter the package name: `com.example.tene`
4. Download the `google-services.json` file and place it in the `android/app` directory

### iOS Setup
1. Go to the [Firebase Console](https://console.firebase.google.com/project/tene-emotions/overview)
2. Navigate to Project Settings > Add app > iOS
3. Enter the bundle ID: `com.example.tene`
4. Download the `GoogleService-Info.plist` file and place it in the `ios/Runner` directory

## Production Environment (tene-emotions-prod)

### Android Setup
1. Go to the [Firebase Console](https://console.firebase.google.com/project/tene-emotions-prod/overview)
2. Navigate to Project Settings > Add app > Android
3. Enter the package name: `com.teneapp.production`
4. Download the `google-services.json` file and save it as `google-services.json` in the `android/app` directory when building for production

### iOS Setup
1. Go to the [Firebase Console](https://console.firebase.google.com/project/tene-emotions-prod/overview)
2. Navigate to Project Settings > Add app > iOS 
3. Enter the bundle ID: `com.teneapp.production`
4. Download the `GoogleService-Info.plist` file and place it in the `ios/Runner` directory when building for production

## Running the App

### Development Environment
```bash
# For Windows
run_dev.bat

# For PowerShell
./run_dev.ps1
```

### Production Environment
```bash
# For Windows
run_prod.bat

# For PowerShell
./run_prod.ps1
``` 