// Main providers file for the app
// Contains all provider implementations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/models/tene_model.dart';
import 'package:tene/services/tene_service.dart';

/// Simple weather data model for display
class WeatherData {
  final String icon;
  final String temperature;

  const WeatherData({required this.icon, required this.temperature});
}

/// List of moods for cycling through
final cyclableMoods = ['loved', 'cozy', 'jhappi', 'excited', 'relaxed', 'sad', 'angry'];

/// Get the next mood in the cycle
String getNextMood(String currentMood) {
  final currentIndex = cyclableMoods.indexOf(currentMood);
  if (currentIndex == -1) return cyclableMoods.first;

  final nextIndex = (currentIndex + 1) % cyclableMoods.length;
  return cyclableMoods[nextIndex];
}

/// Get the previous mood in the cycle
String getPreviousMood(String currentMood) {
  final currentIndex = cyclableMoods.indexOf(currentMood);
  if (currentIndex == -1) return cyclableMoods.last;

  final previousIndex = (currentIndex - 1 + cyclableMoods.length) % cyclableMoods.length;
  return cyclableMoods[previousIndex];
}

/// Provider for the TeneService
final teneServiceProvider = Provider<TeneService>((ref) {
  return TeneService();
});

/// Update unviewedTenesProvider to use TeneService
final unviewedTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getUnviewedTenes();
});

/// Provider for tracking current Tene selected in the feed
final selectedTeneProvider = StateProvider<TeneModel?>((ref) => null);

/// Provider for tracking current mood selection
final currentMoodProvider = StateProvider<String>((ref) => 'loved');

/// Provider for notification settings
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider that gives access to the current mood data
final currentMoodDataProvider = Provider<MoodData>((ref) {
  final currentMoodId = ref.watch(currentMoodProvider);
  return moodMap[currentMoodId] ?? moodMap['jhappi']!;
});

/// Provider for storing the selected GIF URL
final selectedGifProvider = StateProvider<String?>((ref) => null);

/// Provider for storing the selected contact phone number
final selectedContactProvider = StateProvider<String?>((ref) => null);

/// Provider for app theme based on current mood
final appThemeProvider = Provider<ThemeData>((ref) {
  final moodData = ref.watch(currentMoodDataProvider);

  return ThemeData(
    visualDensity: VisualDensity.compact,
    colorScheme: ColorScheme.fromSeed(
      seedColor: moodData.primaryColor,
      primary: moodData.primaryColor,
      secondary: moodData.secondaryColor,
      brightness: Brightness.dark,
    ),
    textTheme: TextTheme(
      bodyLarge: moodData.textStyle,
      bodyMedium: moodData.textStyle,
      labelLarge: moodData.textStyle,
    ),
    floatingActionButtonTheme: moodData.fabTheme,
    buttonTheme: const ButtonThemeData(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minWidth: 0,
      height: 36,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
  );
});

/// Provider for tracking onboarding screen index
final onboardingScreenIndexProvider = StateProvider<int>((ref) => 0);

/// StreamProvider for unviewed Tenes by phone number
final unviewedTenesByPhoneProvider = StreamProvider.family<List<TeneData>, String>((
  ref,
  phoneNumber,
) {
  final teneService = ref.watch(teneServiceProvider);

  if (phoneNumber.isEmpty) {
    return Stream.value([]);
  }

  // Use getReceivedTenes and filter by the sender's phone number
  return teneService.getReceivedTenes().map((tenes) {
    return tenes.where((tene) => tene.senderPhone == phoneNumber).toList();
  });
});
