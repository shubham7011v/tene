import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/models/tene_model.dart';
import 'package:tene/services/firebase_service.dart';
export 'app_providers.dart';

/// Provider for the Firebase service
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// StreamProvider for unviewed Tenes
final unviewedTenesProvider = StreamProvider<List<TeneModel>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getUnviewedTenes();
});

/// Provider for tracking current Tene selected in the feed
final selectedTeneProvider = StateProvider<TeneModel?>((ref) => null);

/// Provider for tracking current mood selection
final currentMoodProvider = StateProvider<String>((ref) => 'jhappi');

/// Provider that gives access to the current mood data
final currentMoodDataProvider = Provider<MoodData>((ref) {
  final currentMoodId = ref.watch(currentMoodProvider);
  return moodMap[currentMoodId] ?? moodMap['jhappi']!;
});

/// Provider for storing the selected GIF URL
final selectedGifProvider = StateProvider<String?>((ref) => null);

/// Provider for storing the selected contact phone number
final selectedContactProvider = StateProvider<String?>((ref) => null);

/// Provider for a dynamic theme based on current mood
final moodThemeProvider = Provider<ThemeData>((ref) {
  final moodData = ref.watch(currentMoodDataProvider);
  
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: moodData.primaryColor,
      primary: moodData.primaryColor,
      secondary: moodData.secondaryColor,
    ),
    scaffoldBackgroundColor: moodData.primaryColor.withAlpha(51),
    appBarTheme: AppBarTheme(
      backgroundColor: moodData.primaryColor,
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: moodData.secondaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );
});

/// Provider for tracking onboarding screen index
final onboardingScreenIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for tracking authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
}); 