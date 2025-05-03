# GitHub Workflow Setup for Flutter and Firebase

This guide explains how to set up and use the GitHub Actions workflow for Flutter app testing, building, and Firebase deployment.

## Files Overview

- `.github/workflows/firebase_ci.yml` - GitHub Actions workflow configuration
- `firestore.rules` - Firebase Firestore security rules
- `firestore.indexes.json` - Firestore indexes configuration
- `firebase.json` - Firebase project configuration
- `storage.rules` - Firebase Storage security rules

## Setup Instructions

### 1. Generate Firebase Deployment Token

To allow GitHub Actions to deploy to Firebase, you need to generate a CI token:

```bash
# Install Firebase CLI if you haven't already
npm install -g firebase-tools

# Login and generate token
firebase login
firebase login:ci
```

The command will output a token. Save this for the next step.

### 2. Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and Variables > Actions
3. Add the following secrets:
   - `FIREBASE_DEPLOY_TOKEN`: Your Firebase CI token from step 1
   - `ENV_PROD` (optional): Contents of your .env.prod file for environment variables

### 3. Configure Firebase Project

Make sure your local Firebase configuration matches the repository:

```bash
# Initialize Firebase in your project if not already done
firebase init
```

This will help you set up the necessary Firebase files if they don't exist yet.

### 4. Push to Main Branch

The workflow will automatically run on pushes to the main branch:
- It will build and test your Flutter app
- Create a debug APK artifact you can download
- Deploy Firestore rules to Firebase

## Using Environment Variables

For sensitive variables like API keys:

1. Create a `.env.prod` file locally with your secrets
2. Never commit this file (it's in .gitignore)
3. Store the contents in the `ENV_PROD` GitHub secret
4. The workflow will recreate this file during deployment

## Customizing the Workflow

- Edit `.github/workflows/firebase_ci.yml` to change the workflow behavior
- Modify `firestore.rules` to update your Firestore security rules
- Update `firebase.json` to change your Firebase configuration

## Troubleshooting

Common issues:

1. **Authentication Failure**: Check your `FIREBASE_DEPLOY_TOKEN` and regenerate if necessary
2. **Build Failures**: Ensure your Flutter app builds locally before pushing
3. **Rule Deployment Failure**: Validate your rules using the Firebase Emulator Suite before deployment 