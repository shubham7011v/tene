# Tene App

A Flutter application with mood-based UI and GIPHY integration.

## Environment Setup

### API Keys

This app uses environment variables to securely store API keys. To set up:

1. Create a file named `.env` in the root project directory
2. Add your GIPHY API key to the file in the following format:

```
GIPHY_API_KEY=your_api_key_here
```

3. Replace `your_api_key_here` with your actual GIPHY API key
4. Get a GIPHY API key from: https://developers.giphy.com/dashboard/

### Important Security Notes

- **NEVER** commit your `.env` file to version control
- The `.env` file is included in `.gitignore` to prevent accidental commits
- For team members, share the format but not the actual API keys

## Running the App

1. Make sure you have set up the `.env` file as described above
2. Run the app with:

```
flutter run
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
