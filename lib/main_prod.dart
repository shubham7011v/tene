import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tene/config/env_config.dart';
import 'package:tene/firebase_options_prod.dart';
import 'main.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize the production environment
    await EnvironmentConfig.initialize(env: Environment.production);

    // Initialize Firebase explicitly
    await Firebase.initializeApp(options: DefaultProdFirebaseOptions.currentPlatform);

    // Launch the app with production configuration (no debug indicators)
    runApp(const ProviderScope(child: MyApp(debugBanner: false, environmentBadge: false)));
  } catch (e) {
    debugPrint('Error during production environment initialization: $e');
    // Fallback to basic configuration even if environment setup fails
    runApp(const ProviderScope(child: MyApp(debugBanner: false, environmentBadge: false)));
  }
}
