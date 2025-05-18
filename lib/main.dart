import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tene/firebase_options_dev.dart';
import 'package:tene/firebase_options_prod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/services/mood_storage_service.dart';
import 'package:tene/screens/auth_wrapper.dart';
import 'package:tene/services/service_locator.dart';
import 'package:tene/config/env_config.dart';

// Main function is now just for direct run
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Default to development environment when run directly
    await EnvironmentConfig.initialize(env: Environment.development);

    // Initialize Firebase first
    await Firebase.initializeApp(
      options:
          EnvironmentConfig.isProduction
              ? DefaultProdFirebaseOptions.currentPlatform
              : DefaultDevFirebaseOptions.currentPlatform,
    );

    // Initialize other services
    await ServiceLocator.instance.initialize();

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    print('Error initializing app: $e');
    rethrow;
  }
}

/// The main app widget that configures the application
class MyApp extends ConsumerStatefulWidget {
  final bool debugBanner;
  final bool environmentBadge;

  const MyApp({super.key, this.debugBanner = true, this.environmentBadge = true});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Only try to initialize Firebase if it wasn't initialized in main
      if (Firebase.apps.isEmpty) {
        await _initializeFirebase();
      }

      // Initialize service locator
      await ServiceLocator.instance.initialize();

      // Initialize the saved mood
      _initializeSavedMood();
    } catch (e) {
      debugPrint('Error during app initialization: $e');
    }
  }

  /// Safely initialize Firebase handling the duplicate app case
  Future<FirebaseApp?> _initializeFirebase() async {
    try {
      // Initialize Firebase with the environment-specific options
      final firebaseOptions =
          EnvironmentConfig.isProduction
              ? DefaultProdFirebaseOptions.currentPlatform
              : DefaultDevFirebaseOptions.currentPlatform;

      debugPrint('Initializing Firebase for ${EnvironmentConfig.environmentName}');

      // Initialize with default app name
      return await Firebase.initializeApp(options: firebaseOptions);
    } catch (e) {
      debugPrint('Firebase initialization error: $e');

      if (e.toString().contains('duplicate-app')) {
        debugPrint('Firebase already initialized, returning default app');
        return Firebase.apps.isNotEmpty ? Firebase.apps.first : null;
      }

      return null;
    }
  }

  // Initialize the saved mood from SharedPreferences
  Future<void> _initializeSavedMood() async {
    final lastSelectedMood = await MoodStorageService.getLastSelectedMood();

    // If we have a saved mood, set it as the current mood
    if (lastSelectedMood != null && mounted) {
      // Update on the next frame to avoid setState during build
      Future.microtask(() {
        ref.read(currentMoodProvider.notifier).state = lastSelectedMood;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine app title based on environment
    final appTitle = EnvironmentConfig.isDevelopment ? 'Tene Dev' : 'Tene';

    return MaterialApp(
      title: appTitle,
      theme: ref.watch(appThemeProvider),
      home: Stack(
        children: [
          const AuthWrapper(),

          // Show environment badge in development mode
          if (widget.environmentBadge && EnvironmentConfig.isDevelopment)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.only(top: 30, bottom: 4),
                child: const Text(
                  'DEVELOPMENT',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      builder: (context, child) {
        // Add extra padding around the entire app
        return MediaQuery(
          // Set a smaller text scale factor to prevent text overflow
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.of(context).padding.copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 8, // Add extra bottom padding
            ),
            textScaler: const TextScaler.linear(0.95),
          ),
          child: Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8), // Extra bottom buffer
                child: child!,
              );
            },
          ),
        );
      },
      debugShowCheckedModeBanner: widget.debugBanner,
    );
  }
}
