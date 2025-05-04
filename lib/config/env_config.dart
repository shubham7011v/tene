import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment types for the application
enum Environment { development, production }

/// Configuration class for handling environment-specific settings
class EnvironmentConfig {
  static late Environment _environment;
  static late Map<String, String> _config;

  /// Initialize the environment configuration
  static Future<void> initialize({Environment env = Environment.development}) async {
    _environment = env;

    try {
      await _loadEnvFile();
    } catch (e) {
      debugPrint('Error loading .env file: $e');
      // Create default configuration if env file fails to load
      _config = _createDefaultConfig();
      return;
    }

    _config = {
      'API_URL': dotenv.get('API_URL', fallback: _getDefaultApiUrl()),
      'GIPHY_API_KEY': dotenv.get('GIPHY_API_KEY', fallback: 'YOUR_GIPHY_API_KEY'),
      'FIREBASE_PROJECT_ID': dotenv.get('FIREBASE_PROJECT_ID', fallback: 'tene-emotions'),
    };

    debugPrint('Environment config loaded for: $environmentName');
  }

  /// Load the appropriate .env file based on the environment
  static Future<void> _loadEnvFile() async {
    try {
      switch (_environment) {
        case Environment.development:
          await dotenv.load(fileName: '.env.dev');
          break;
        case Environment.production:
          await dotenv.load(fileName: '.env.prod');
          break;
      }
    } catch (e) {
      debugPrint('Error loading environment file: $e');
      // Let the error propagate to initialize for handling
      rethrow;
    }
  }

  /// Create default configuration if env file loading fails
  static Map<String, String> _createDefaultConfig() {
    debugPrint('Using default configuration for $environmentName');
    return {
      'API_URL': _getDefaultApiUrl(),
      'GIPHY_API_KEY': 'YOUR_GIPHY_API_KEY',
      'FIREBASE_PROJECT_ID': 'tene-emotions',
    };
  }

  /// Get default API URL based on environment
  static String _getDefaultApiUrl() {
    return _environment == Environment.development
        ? 'https://api.dev.example.com'
        : 'https://api.example.com';
  }

  /// Get the current environment
  static Environment get environment => _environment;

  /// Check if the app is running in development mode
  static bool get isDevelopment => _environment == Environment.development;

  /// Check if the app is running in production mode
  static bool get isProduction => _environment == Environment.production;

  /// Get a configuration value by key
  static String get(String key) => _config[key] ?? '';

  /// Get environment-specific properties
  static String get apiUrl => get('API_URL');
  static String get giphyApiKey => get('GIPHY_API_KEY');
  static String get firebaseProjectId => get('FIREBASE_PROJECT_ID');

  /// Get environment name for display
  static String get environmentName => _environment.toString().split('.').last;
}
