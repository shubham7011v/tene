// Export all providers
export 'app_providers.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/models/tene_model.dart';
import 'package:tene/services/firebase_service.dart';

/// Simple weather data model for display
class WeatherData {
  final String icon;
  final String temperature;

  const WeatherData({
    required this.icon,
    required this.temperature,
  });
}

/// Seasonal theme data
class SeasonalTheme {
  final String name;
  final String animationPath;
  final String tagline;
  
  const SeasonalTheme({
    required this.name,
    required this.animationPath,
    required this.tagline,
  });
}

/// Theme mode enum with descriptive labels
enum AppThemeMode {
  system('System'),
  light('Light'),
  dark('Dark');
  
  final String label;
  const AppThemeMode(this.label);
}

/// Map of mood IDs to their Lottie animation paths
final moodLottieMap = {
  'jhappi': 'assets/animations/hug.json',
  'sad': 'assets/animations/sad.json',
  'angry': 'assets/animations/angry.json',
  'relaxed': 'assets/animations/relaxed.json',
  'excited': 'assets/animations/excited.json',
  'crush': 'assets/animations/crush.json',
  'lol': 'assets/animations/lol.json',
  'thappad': 'assets/animations/thappad.json',
  'cozy': 'assets/animations/cozy.json',
  'loved': 'assets/animations/loved.json',
};

/// Map of mood IDs to their backdrop Lottie animation paths
final moodLottieBackdropMap = {
  'jhappi': 'assets/animations/mood_backdrops/jhappi_snow.json',
  'sad': 'assets/animations/mood_backdrops/sad_snow.json',
  'angry': 'assets/animations/mood_backdrops/angry_snow.json',
  'relaxed': 'assets/animations/mood_backdrops/relaxed_snow.json',
  'excited': 'assets/animations/mood_backdrops/excited_snow.json',
  'cozy': 'assets/animations/mood_backdrops/cozy_snow.json',
  'loved': 'assets/animations/mood_backdrops/loved_snow.json',
};

/// List of moods for cycling through
final cyclableMoods = ['loved', 'cozy', 'jhappi', 'excited', 'relaxed', 'sad', 'angry'];

/// Get the next mood in the cycle
String getNextMood(String currentMood) {
  final currentIndex = cyclableMoods.indexOf(currentMood);
  if (currentIndex == -1) return cyclableMoods.first;
  
  final nextIndex = (currentIndex + 1) % cyclableMoods.length;
  return cyclableMoods[nextIndex];
}

/// Available seasonal themes
final seasonalThemes = [
  const SeasonalTheme(
    name: 'Spring',
    animationPath: 'assets/animations/spring_theme.json',
    tagline: 'Spring brings new vibes',
  ),
  const SeasonalTheme(
    name: 'Summer',
    animationPath: 'assets/animations/summer_theme.json',
    tagline: 'Summer calls for a Splash',
  ),
  const SeasonalTheme(
    name: 'Monsoon',
    animationPath: 'assets/animations/rain_theme.json',
    tagline: 'Rainy days call for a Jhappi',
  ),
  const SeasonalTheme(
    name: 'Autumn',
    animationPath: 'assets/animations/autumn_theme.json',
    tagline: 'Fall into new emotions',
  ),
  const SeasonalTheme(
    name: 'Winter',
    animationPath: 'assets/animations/winter_theme.json',
    tagline: '',
  ),
  const SeasonalTheme(
    name: 'Holi',
    animationPath: 'assets/animations/holi_theme.json',
    tagline: 'Colors of emotions',
  ),
  const SeasonalTheme(
    name: 'Diwali',
    animationPath: 'assets/animations/diwali_theme.json',
    tagline: 'Light up someone\'s mood',
  ),
];

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
final currentMoodProvider = StateProvider<String>((ref) => 'loved');

/// Provider for the app's theme mode
final appThemeModeProvider = StateProvider<AppThemeMode>((ref) => AppThemeMode.system);

/// Provider for notification settings
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for user profile data
final userProfileProvider = StateProvider<Map<String, dynamic>>((ref) {
  // Default values, would be populated from Firebase in a real app
  return {
    'name': 'User',
    'avatarUrl': null,
    'initialLetter': 'U',
  };
});

/// Provider that gives access to the current mood data
final currentMoodDataProvider = Provider<MoodData>((ref) {
  final currentMoodId = ref.watch(currentMoodProvider);
  return moodMap[currentMoodId] ?? moodMap['jhappi']!;
});

/// Provider for current mood's Lottie animation path
final currentMoodLottieProvider = Provider<String>((ref) {
  final currentMoodId = ref.watch(currentMoodProvider);
  return moodLottieMap[currentMoodId] ?? moodLottieMap['jhappi']!;
});

/// Provider for current mood's backdrop Lottie animation path
final currentMoodBackdropProvider = Provider<String>((ref) {
  final currentMoodId = ref.watch(currentMoodProvider);
  return moodLottieBackdropMap[currentMoodId] ?? moodLottieBackdropMap['jhappi']!;
});

/// Provider for the current seasonal theme
final currentSeasonalThemeProvider = Provider<SeasonalTheme>((ref) {
  // In a real app, this would be determined by date or user preference
  // Setting to Winter theme as requested
  return seasonalThemes.firstWhere((theme) => theme.name == 'Winter');
});

/// Provider for storing the selected GIF URL
final selectedGifProvider = StateProvider<String?>((ref) => null);

/// Provider for storing the selected contact phone number
final selectedContactProvider = StateProvider<String?>((ref) => null);

/// Mock weather provider (would be replaced with actual API in production)
final weatherProvider = Provider<WeatherData>((ref) {
  // In a real app, this would fetch actual weather data
  return const WeatherData(
    icon: '☀️',
    temperature: '28°C',
  );
});

/// Provider for a dynamic theme based on current mood
final moodThemeProvider = Provider<ThemeData>((ref) {
  final moodData = ref.watch(currentMoodDataProvider);
  final appThemeMode = ref.watch(appThemeModeProvider);
  
  final isDarkMode = switch (appThemeMode) {
    AppThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
    AppThemeMode.dark => true,
    AppThemeMode.light => false,
  };
  
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: moodData.primaryColor,
      primary: moodData.primaryColor,
      secondary: moodData.secondaryColor,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: isDarkMode 
      ? Colors.grey.shade900 
      : moodData.primaryColor.withAlpha(51),
    appBarTheme: AppBarTheme(
      backgroundColor: moodData.primaryColor,
      foregroundColor: isDarkMode ? Colors.white : Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: moodData.secondaryColor,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
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