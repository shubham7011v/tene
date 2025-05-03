# Multi-Environment Setup for Tene

This document explains how to use the multi-environment configuration (development and production) for the Tene app.

## Environment Files

The app uses different environment files for development and production:

- `.env.dev` - Development environment variables
- `.env.prod` - Production environment variables

These files contain environment-specific variables like API keys, URLs, and other configuration settings.

## Firebase Configurations

There are separate Firebase configuration files for each environment:

- `lib/firebase_options_dev.dart` - Firebase configuration for development
- `lib/firebase_options_prod.dart` - Firebase configuration for production

These files were generated using the FlutterFire CLI:

```bash
flutterfire configure --project=<dev_project_id> --out=lib/firebase_options_dev.dart
flutterfire configure --project=<prod_project_id> --out=lib/firebase_options_prod.dart
```

## Running the App

### Using Scripts

For convenience, there are scripts to run the app in different environments:

**Windows CMD:**
```
run_dev.bat    # Run in development mode
run_prod.bat   # Run in production mode
```

**PowerShell:**
```
./run_dev.ps1  # Run in development mode
./run_prod.ps1 # Run in production mode
```

### Manual Running

You can also run the app manually with the `--dart-define` flag:

```bash
# Development
flutter run --dart-define=ENV=dev

# Production
flutter run --dart-define=ENV=prod
```

## Building for Release

To build a release version for a specific environment:

```bash
# Development APK
flutter build apk --dart-define=ENV=dev

# Production APK
flutter build apk --dart-define=ENV=prod

# Development iOS
flutter build ios --dart-define=ENV=dev

# Production iOS
flutter build ios --dart-define=ENV=prod
```

## Code Usage

In your code, you can access environment variables and settings using the `Environment` class:

```dart
import 'package:tene/config/environment.dart';

// Check the current environment
if (Environment.isProduction) {
  // Do production stuff
} else {
  // Do development stuff
}

// Get environment-specific values
final apiKey = Environment.get('API_KEY');
final giphyKey = Environment.giphyApiKey;
final baseUrl = Environment.baseUrl;

// Get environment name
print('Running in ${Environment.environmentName}');
```

## Visual Indicator

In development mode, the app displays an environment banner in the top-right corner. This banner is hidden in production by default.

To show the banner in all environments (including production), use:

```dart
EnvironmentBanner(
  alwaysShow: true,
  child: YourWidget(),
)
```

## Adding New Environment Variables

To add a new environment variable:

1. Add it to both `.env.dev` and `.env.prod` files
2. Access it in code using `Environment.get('VARIABLE_NAME')`
3. For commonly used variables, consider adding a getter in the `Environment` class 