import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// A class for handling environment-specific configurations
class Environment {
  /// The current environment: 'dev' or 'prod'
  static String get flavor => const String.fromEnvironment('ENV', defaultValue: 'dev');

  /// Whether we're running in production mode
  static bool get isProduction => flavor == 'prod';

  /// Whether we're running in development mode
  static bool get isDevelopment => flavor == 'dev';

  /// Whether we're in debug or release mode
  static bool get isDebugMode => kDebugMode;

  /// Gets a value from the environment file, with a provided fallback
  static String get(String key, {String fallback = ''}) {
    return dotenv.env[key] ?? fallback;
  }

  /// Gets the base API URL for the current environment
  static String get baseUrl => get('BASE_URL', fallback: 'https://api.example.com');

  /// Gets the Giphy API key for the current environment
  static String get giphyApiKey => get('GIPHY_API_KEY', fallback: '');

  /// Gets the Firebase environment name
  static String get firebaseEnv => get('FIREBASE_ENV', fallback: 'dev');

  /// A helper for debugging to get all environment variables
  static Map<String, String> get all => dotenv.env;

  /// Returns a friendly name for the current environment
  static String get environmentName =>
      isProduction
          ? 'Production'
          : isDebugMode
          ? 'Development (Debug)'
          : 'Development';

  @override
  String toString() => 'Environment(flavor: $flavor, isDebug: $isDebugMode)';
}
