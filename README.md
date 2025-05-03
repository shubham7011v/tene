# Tene App

A Flutter application for sharing mood-based messages with friends. Tene lets users send emotional messages with custom backgrounds using GIPHY integration and Firebase backend.

![Tene App Banner](https://example.com/banner-image.png)

## 📱 Features

- **Mood-Based Messaging**: Send messages with different emotion-based themes
- **GIF Integration**: Add GIPHY GIFs to enhance your messages
- **Real-time Updates**: Firebase Firestore integration for instant message delivery
- **Secure Authentication**: Firebase Authentication for user management
- **Responsive Design**: Works on iOS and Android devices

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.19.x or later)
- Dart SDK (3.0.0 or later)
- Firebase account
- GIPHY Developer API key

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/tene.git
   cd tene
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Set up environment variables
   - Create a `.env` file in the root directory
   - Add your GIPHY API key:
     ```
     GIPHY_API_KEY=your_api_key_here
     ```

4. Connect to Firebase
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Firestore, Authentication, and Storage
   - Download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS)
   - Place them in the appropriate directories

5. Run the app
   ```bash
   flutter run
   ```

## 📚 Documentation

- [Project Structure](./docs/PROJECT_STRUCTURE.md) - Overview of the project architecture
- [Development Guide](./docs/DEVELOPMENT_GUIDE.md) - Guidelines for development
- [API Reference](./docs/API_REFERENCE.md) - Reference for data models and services
- [Firebase Setup](./GITHUB_WORKFLOW_SETUP.md) - Instructions for Firebase configuration and CI/CD
- [Environment Setup](./ENVIRONMENT.md) - Details on environment configuration
- [VS Code Setup](./VSCODE.md) - VS Code editor configuration for the project
- [Git Workflow](./GIT.md) - Git best practices for the project

## 🧪 Testing

Run tests with:

```bash
flutter test
```

## 🔒 Security Rules

Firebase security rules are managed in the `firestore.rules` file. CI/CD pipelines automatically deploy these rules when changes are pushed to the main branch.

## 🛠️ Built With

- [Flutter](https://flutter.dev/) - UI framework
- [Firebase](https://firebase.google.com/) - Backend and authentication
- [Provider](https://pub.dev/packages/provider) - State management
- [GIPHY SDK](https://developers.giphy.com/) - GIF integration

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Contributors

- Your Name - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev/team)
- [Firebase](https://firebase.google.com/)
- [GIPHY](https://giphy.com/)

## How to Fix the Launcher Icon Issue

You're seeing a build error about missing launcher icons. To fix this:

### Option 1: Quick Fix (manual)

1. Create a PNG image of size 192x192 pixels
2. Save it as `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
3. Copy the same file to these folders (creating them if needed):
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144px)
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96px)
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48px)
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72px)

### Option 2: Use Flutter Launcher Icons

1. Create a PNG image for your app icon (512x512px recommended)
2. Save it as `assets/images/app_icon.png`
3. Run this command:
   ```
   flutter pub run flutter_launcher_icons
   ```

After doing either option, run:
```
flutter clean
flutter pub get
```

Then try building your app again.
