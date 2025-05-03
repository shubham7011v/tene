# Tene App Project Structure

This document provides an overview of the Tene app's project structure and architecture.

## Directory Structure

```
tene/
├── .github/workflows/     # GitHub Actions workflows
├── android/               # Android-specific code
├── assets/                # Static assets like images
├── ios/                   # iOS-specific code
├── lib/                   # Main Dart code
│   ├── config/            # App configuration
│   ├── models/            # Data models
│   ├── providers/         # State management
│   ├── screens/           # UI screens
│   ├── services/          # Backend services
│   ├── utils/             # Utility functions
│   ├── widgets/           # Reusable UI components
│   ├── main.dart          # App entry point
│   ├── firebase_options_dev.dart  # Dev environment Firebase config
│   └── firebase_options_prod.dart # Prod environment Firebase config
├── test/                  # Test files
├── web/                   # Web-specific code
├── firestore.rules        # Firestore security rules
├── firebase.json          # Firebase configuration
└── storage.rules          # Firebase Storage rules
```

## Architecture Overview

Tene follows a layered architecture with clear separation of concerns:

1. **Data Layer**
   - `models/`: Data models (TeneModel, MoodData)
   - `services/`: Backend integration (Firebase, Auth)

2. **Business Logic Layer**
   - `providers/`: State management using Provider

3. **Presentation Layer**
   - `screens/`: UI screens
   - `widgets/`: Reusable UI components

## Key Components

### Models

- **TeneModel**: Represents a mood-based message between users
- **MoodData**: Contains mood information including colors and emoji

### Screens

- **HomeScreen**: Main app interface
- **LoginScreen**: User authentication
- **ProfileScreen**: User profile management
- **GiphyPickerScreen**: Interface for selecting GIFs
- **ContactPickerScreen**: Interface for selecting recipients
- **ReceiveTeneScreen**: Display for received messages

### Services

- **FirebaseService**: Handles Firestore database operations
- **AuthService**: Manages user authentication
- **MoodStorageService**: Manages mood preference storage

## State Management

The app uses Provider for state management, with the following key providers:

- User authentication state
- Current mood selection
- Message history

## Firebase Integration

Tene uses several Firebase services:

- **Firestore**: For storing messages and user data
- **Authentication**: For user management
- **Storage**: For storing media like profile pictures
- **Firebase Functions** (optional): For server-side operations

## Security

Security is implemented through:

- Firebase Authentication for user identity
- Firestore security rules for data access control
- Environment variables for API keys 