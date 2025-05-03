# Tene App Environment Setup Guide

This guide provides step-by-step instructions to set up development and production environments for the Tene app.

## 1. Environment Files Setup

Create `.env.dev` and `.env.prod` files in the project root:

### .env.dev (Development)
```
API_URL=https://api-dev.teneapp.com
GIPHY_API_KEY=your_dev_giphy_api_key
FIREBASE_PROJECT_ID=tene-dev-12345
ENV=development
```

### .env.prod (Production)
```
API_URL=https://api.teneapp.com
GIPHY_API_KEY=your_prod_giphy_api_key
FIREBASE_PROJECT_ID=tene-prod-12345
ENV=production
```

## 2. App Icons Setup

### Development App Icon

1. Create a development icon with a visible "DEV" badge.
2. Place the icon files in these directories:
   ```
   android/app/src/dev/res/mipmap-hdpi/ic_launcher.png
   android/app/src/dev/res/mipmap-mdpi/ic_launcher.png
   android/app/src/dev/res/mipmap-xhdpi/ic_launcher.png
   android/app/src/dev/res/mipmap-xxhdpi/ic_launcher.png
   android/app/src/dev/res/mipmap-xxxhdpi/ic_launcher.png
   ```

### Production App Icon

1. Use the standard app icon without any badge.
2. Place the icon files in these directories:
   ```
   android/app/src/prod/res/mipmap-hdpi/ic_launcher.png
   android/app/src/prod/res/mipmap-mdpi/ic_launcher.png
   android/app/src/prod/res/mipmap-xhdpi/ic_launcher.png
   android/app/src/prod/res/mipmap-xxhdpi/ic_launcher.png
   android/app/src/prod/res/mipmap-xxxhdpi/ic_launcher.png
   ```

## 3. Firebase Setup

### Development Firebase Project

1. Create a development Firebase project in the Firebase console.
2. Download the `google-services.json` for development.
3. Place it at: `android/app/src/dev/google-services.json`

### Production Firebase Project

1. Create a production Firebase project in the Firebase console.
2. Download the `google-services.json` for production.
3. Place it at: `android/app/src/prod/google-services.json`

## 4. Running the App

### Using VS Code (Recommended)

We've set up VS Code configuration to make it easy to run the app in different environments:

1. Open the project in VS Code
2. Press `F5` or click the "Run and Debug" icon in the sidebar
3. Select from the dropdown at the top of the Debug panel:
   - **Tene Development**: Run the app in development mode
   - **Tene Production**: Run the app in production mode

You can also create a release or profile build by selecting the corresponding configuration.

### Using Tasks in VS Code

We've also created VS Code tasks to help with building APKs:

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
2. Type "Tasks: Run Task" and select it
3. Choose one of the following:
   - **Build Development APK**: Creates a development APK
   - **Build Production APK**: Creates a production APK
   - **Clean Project**: Runs flutter clean
   - **Get Packages**: Runs flutter pub get

### Using Command Line

1. To run in development mode:
   ```
   flutter run --flavor dev -t lib/main_dev.dart
   ```

2. To run in production mode:
   ```
   flutter run --flavor prod -t lib/main_prod.dart
   ```

## 5. Building the App

### Building Development APK

```
flutter build apk --flavor dev -t lib/main_dev.dart
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-dev-release.apk`

### Building Production APK

```
flutter build apk --flavor prod -t lib/main_prod.dart
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-prod-release.apk`

## 6. iOS Configuration (Future Task)

For iOS, similar configuration will be needed using Xcode schemes and targets.

## Key Differences Between Environments

1. **App Name:**
   - Development: "Tene Dev"
   - Production: "Tene"

2. **Package ID:**
   - Development: com.example.tene
   - Production: com.example.tene

3. **App Icon:**
   - Development: Has a "DEV" badge
   - Production: Standard icon

4. **Visual Indicator:**
   - Development: Red "DEVELOPMENT" banner at the top
   - Production: No banner

5. **Debug Banner:**
   - Development: Visible in top-right corner
   - Production: Hidden 

## VS Code Environment Indicators

The VS Code configuration includes a visual indicator for the current environment:

- **Status Bar Color**: The status bar in VS Code will show red for the development environment
- **Debug Panel**: The active launch configuration will indicate which environment you're using 