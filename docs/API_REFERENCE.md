# Tene App API Reference

This document provides reference documentation for the Tene app's data models and services.

## Data Models

### TeneModel

Represents a mood-based message sent between users.

#### Properties

| Property      | Type             | Description                                   |
|---------------|------------------|-----------------------------------------------|
| `id`          | String           | Unique identifier for the message             |
| `senderId`    | String           | Firebase UID of the sender                    |
| `senderName`  | String           | Display name of the sender                    |
| `phoneNumber` | String           | Recipient's phone number (legacy)             |
| `fromPhone`   | String           | Sender's phone number                         |
| `toPhone`     | String           | Recipient's phone number                      |
| `moodId`      | String           | Identifier for the mood (matches `MoodData`)  |
| `moodEmoji`   | String           | Emoji representation of the mood              |
| `gifUrl`      | String?          | Optional URL to a GIPHY GIF                   |
| `timestamp`   | DateTime         | When the message was sent                     |
| `viewed`      | bool             | Whether the message has been viewed           |

#### Methods

| Method                  | Return Type        | Description                                   |
|-------------------------|-------------------|-----------------------------------------------|
| `fromFirestore`         | TeneModel        | Factory to create model from Firestore doc    |
| `toMap`                 | Map<String, dynamic> | Convert model to map for Firestore storage    |
| `copyWith`              | TeneModel        | Create a copy with updated fields             |

### MoodData

Contains visual properties for different moods.

#### Properties

| Property          | Type           | Description                                   |
|-------------------|----------------|-----------------------------------------------|
| `id`              | String         | Unique identifier for the mood                |
| `emoji`           | String         | Emoji representation of the mood              |
| `name`            | String         | Human-readable name of the mood               |
| `primaryColor`    | Color          | Primary UI color for this mood                |
| `secondaryColor`  | Color          | Secondary UI color for this mood              |

## Services

### FirebaseService

Handles interaction with Firebase Firestore database.

#### Methods

| Method                    | Return Type             | Description                                       |
|---------------------------|------------------------|---------------------------------------------------|
| `sendTene`                | Future<void>           | Sends a new Tene message to a recipient           |
| `getTenesByPhoneNumber`   | Stream<List<TeneModel>> | Stream of Tenes for a specific phone number       |
| `getTeneById`             | Future<TeneModel?>     | Retrieves a specific Tene by ID                   |
| `markTeneAsViewed`        | Future<void>           | Marks a Tene as viewed with optional deletion     |
| `getUserProfile`          | Future<UserProfile?>   | Retrieves a user's profile data                   |
| `updateUserProfile`       | Future<void>           | Updates user profile information                  |

### AuthService

Manages user authentication.

#### Methods

| Method                    | Return Type             | Description                                       |
|---------------------------|------------------------|---------------------------------------------------|
| `signInWithPhone`         | Future<UserCredential>  | Initiates phone authentication flow               |
| `verifyPhoneCode`         | Future<UserCredential>  | Verifies SMS code for phone authentication        |
| `signOut`                 | Future<void>           | Signs out the current user                        |
| `currentUser`             | User?                  | Gets the currently authenticated user             |
| `authStateChanges`        | Stream<User?>          | Stream of authentication state changes            |
| `isUserSignedIn`          | bool                   | Checks if a user is currently signed in           |

### MoodStorageService

Manages local storage for mood preferences.

#### Methods

| Method                    | Return Type             | Description                                       |
|---------------------------|------------------------|---------------------------------------------------|
| `saveCurrentMood`         | Future<void>           | Saves the user's current mood selection           |
| `getCurrentMood`          | Future<String?>        | Retrieves the last selected mood                  |
| `clearMoodData`           | Future<void>           | Clears stored mood data                           |

## Firebase Collections

### Users Collection

Stores user profile information.

#### Fields

| Field             | Type             | Description                                   |
|-------------------|------------------|-----------------------------------------------|
| `uid`             | String           | User's Firebase UID (document ID)             |
| `phoneNumber`     | String           | User's phone number                           |
| `displayName`     | String           | User's display name                           |
| `profileImageUrl` | String?          | Optional URL to profile image                 |
| `createdAt`       | Timestamp        | When the account was created                  |
| `lastActive`      | Timestamp        | When the user was last active                 |

### Tenes Collection

Stores Tene messages sent between users.

#### Fields

| Field             | Type             | Description                                   |
|-------------------|------------------|-----------------------------------------------|
| `senderId`        | String           | UID of the sender                             |
| `senderName`      | String           | Display name of the sender                    |
| `phoneNumber`     | String           | Legacy recipient phone number field           |
| `to`              | String           | Recipient's phone number                      |
| `from`            | String           | Sender's phone number                         |
| `moodId`          | String           | ID of the mood                                |
| `mood`            | String           | Duplicate field for backward compatibility    |
| `moodEmoji`       | String           | Emoji representation of the mood              |
| `media`           | Map              | Media data including URL and type             |
| `timestamp`       | Timestamp        | When the message was sent                     |
| `viewed`          | boolean          | Whether the recipient has viewed the message  | 