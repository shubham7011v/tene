# GitHub Actions for Multi-Environment Flutter App

This document explains the GitHub Actions workflows set up for the Tene app with multi-environment support.

## Available Workflows

### 1. Firebase Rules Deployment (`firebase-deploy.yml`)

Automatically deploys Firebase security rules to the appropriate environment.

- **Triggers**:
  - Push to `main` branch → Deploy to **production**
  - Push to `dev` branch → Deploy to **development**
  - Manual trigger with environment selection

- **Files that trigger deployment**:
  - `firestore.rules.*`
  - `storage.rules`
  - `firestore.indexes.json`

### 2. Flutter Build and Test (`flutter-build.yml`)

Runs tests and builds the Flutter application for both Android and iOS.

- **Triggers**:
  - Push to `main` or `dev` branch
  - Pull requests to `main` or `dev`
  - Manual trigger with environment selection

- **Steps**:
  1. Run Flutter tests
  2. Build Android APK with environment-specific configuration
  3. Build iOS app with environment-specific configuration
  4. Upload build artifacts

### 3. Firebase App Distribution (`firebase-app-distribution.yml`)

Distributes built apps to testers via Firebase App Distribution.

- **Triggers**:
  - After successful completion of "Flutter Build and Test" workflow
  - Manual trigger with environment selection

- **Steps**:
  1. Download build artifacts
  2. Upload to Firebase App Distribution
  3. Notify testers

## Required Secrets

You must add the following secrets to your GitHub repository:

- `FIREBASE_TOKEN`: A Firebase CLI token (get it with `firebase login:ci`)
- `FIREBASE_ANDROID_APP_ID_DEV`: Firebase App ID for development Android app
- `FIREBASE_ANDROID_APP_ID_PROD`: Firebase App ID for production Android app

## Branch Strategy

The workflows are designed to work with the following branch strategy:

- `main` branch: Production environment
- `dev` branch: Development environment
- Feature branches: No automatic deployments

## Manual Workflow Execution

You can manually trigger any workflow:

1. Go to the "Actions" tab in your GitHub repository
2. Select the workflow you want to run
3. Click "Run workflow"
4. Select the branch and environment
5. Click "Run workflow"

## Workflow Dependencies

```
Flutter Build and Test
        ↓
Firebase App Distribution
```

## Environment Variables

The workflows automatically set the appropriate environment variables based on the branch or manual input:

- `ENV=dev` for development environment
- `ENV=prod` for production environment

## Adding New Environments

To add a new environment (e.g., staging):

1. Add a new Firebase project and configuration
2. Create `.env.staging` and `firebase_options_staging.dart`
3. Update the workflow files to include the new environment options
4. Add any new secrets required for the environment 