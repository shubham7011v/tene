import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tene/config/env_config.dart';
import 'package:tene/firebase_options_dev.dart';
import 'main.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize the development environment
    await EnvironmentConfig.initialize(env: Environment.development);

    // Initialize Firebase explicitly
    await Firebase.initializeApp(options: DefaultDevFirebaseOptions.currentPlatform);

    // Add a visual indicator for development builds in debug mode
    debugPrint('RUNNING IN DEVELOPMENT MODE');

    // Launch the app with environment configuration
    runApp(const ProviderScope(child: MyApp(debugBanner: true, environmentBadge: true)));
  } catch (e) {
    debugPrint('Error during development environment initialization: $e');
    // Fallback to basic configuration even if environment setup fails
    runApp(const ProviderScope(child: MyApp(debugBanner: true, environmentBadge: true)));
  }
}
