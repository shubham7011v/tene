# Tene App Environment Setup

This guide explains how to run the Tene app in different environments.

## Environment Configuration

The app supports two environments:
- **Development**: For testing and development purposes
- **Production**: For release builds

## Running Different Environments

### Command Line

To run the app in development environment:

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

To run the app in production environment:

```bash
flutter run --flavor prod -t lib/main_prod.dart
```

### Building APKs

To build a development APK:

```bash
flutter build apk --flavor dev -t lib/main_dev.dart
```

To build a production APK:

```bash
flutter build apk --flavor prod -t lib/main_prod.dart
```

## Visual Differences

The development and production apps have different appearances when installed:

1. **App Name**:
   - Development: "Tene Dev"
   - Production: "Tene"

2. **Package ID**:
   - Development: com.example.tene
   - Production: com.example.tene

3. **App Icon**:
   - Development: Has a "DEV" badge overlaid on the icon
   - Production: Standard app icon

This setup allows you to have both versions installed simultaneously on your device for testing.

## Environment Variables

Environment-specific variables are stored in:
- `.env.dev` - Development environment variables
- `.env.prod` - Production environment variables

Copy the `.env.example` file and rename it to create these files with the appropriate values for each environment.

## Code Architecture

The environment is initialized in the `main_dev.dart` and `main_prod.dart` files, which then call the common app initialization with the appropriate environment configuration. 