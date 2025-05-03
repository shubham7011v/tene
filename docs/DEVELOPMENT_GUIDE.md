# Tene App Development Guide

This guide provides instructions and best practices for developing features for the Tene app.

## Development Environment Setup

### Flutter and Dart

1. Install Flutter by following the [official guide](https://flutter.dev/docs/get-started/install)
2. Ensure you have Flutter 3.19.x or later:
   ```bash
   flutter --version
   ```
3. Configure your IDE (VS Code or Android Studio recommended)
   - Install Flutter and Dart plugins
   - Set up linting and formatting

### Firebase Setup

1. Request access to the Firebase project from the project administrator
2. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```
3. Login to Firebase:
   ```bash
   firebase login
   ```
4. Get the Firebase configuration files:
   - For local development, use the dev environment
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`

### Environment Variables

1. Create `.env.dev` and `.env.prod` files for different environments
2. Include necessary API keys (but never commit these files to Git)
3. For CI/CD, add the variables to GitHub Secrets

## Coding Standards

### Naming Conventions

- **Files**: Snake case (`user_profile.dart`)
- **Classes**: Pascal case (`UserProfile`)
- **Variables/Functions**: Camel case (`userProfile`, `getUserData()`)
- **Constants**: Screaming snake case (`API_KEY`)

### Architecture

Follow the existing architecture pattern:
- **Models**: Data structures with minimal logic
- **Services**: Business logic and external API integration
- **Providers**: State management
- **Screens**: Full UI screens
- **Widgets**: Reusable UI components

### State Management

- Use Provider for simple state management
- Keep providers focused on a single responsibility
- Avoid direct state manipulation in UI components

## Testing

- Write unit tests for all business logic
- Create widget tests for complex UI components
- Follow TDD (Test-Driven Development) when possible
- Run tests before creating pull requests:
  ```bash
  flutter test
  ```

## Git Workflow

1. **Branching Strategy**
   - `main`: Production-ready code
   - `dev`: Development branch
   - Feature branches: `feature/feature-name`
   - Bugfix branches: `bugfix/bug-name`

2. **Commit Messages**
   - Follow conventional commits format
   - Start with a type: `feat:`, `fix:`, `docs:`, `refactor:`, etc.
   - Example: `feat: add mood selector widget`

3. **Pull Requests**
   - Create PRs to the `dev` branch
   - Include a descriptive title and detailed description
   - Link to related issues
   - Ensure tests pass and code is linted
   - Request review from at least one team member

## CI/CD Pipeline

- Automated tests run on every pull request
- Code analysis enforces linting and formatting rules
- Firebase rules are deployed automatically on merge to main

## Firebase Rules

- Test rule changes locally using the Firebase Emulator
- Document any rule changes in comments
- Follow the principle of least privilege
- Consider security implications for each rule change

## Debugging

1. **Flutter DevTools**
   - Use Flutter DevTools for UI debugging
   - Monitor performance with the Performance tab
   - Inspect widget trees to identify layout issues

2. **Firebase Console**
   - Monitor Firebase services through the Firebase Console
   - Use Firebase Analytics to track user behavior
   - Check Crashlytics for crash reports

## Common Issues

1. **Firebase Authentication**
   - Ensure proper error handling for auth failures
   - Test auth flows on both platforms (iOS and Android)

2. **GIPHY Integration**
   - Handle network errors gracefully
   - Implement loading states for API calls

3. **Database Operations**
   - Use transactions for critical operations
   - Implement proper error handling for Firestore operations

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [GIPHY API Documentation](https://developers.giphy.com/docs/api/) 