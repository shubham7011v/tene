enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment environment = Environment.development;

  static bool get isDevelopment => environment == Environment.development;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProduction => environment == Environment.production;

  // Debug features should be available in development and staging
  static bool get showDebugFeatures => isDevelopment || isStaging;

  // API endpoints
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return 'https://dev-api.example.com';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.production:
        return 'https://api.example.com';
    }
  }

  // Feature flags
  static bool get enableAnalytics => isProduction;
  static bool get enableCrashReporting => isProduction;
  static bool get enableLogging => !isProduction;

  // App configuration
  static String get appName {
    switch (environment) {
      case Environment.development:
        return 'Tene Dev';
      case Environment.staging:
        return 'Tene Staging';
      case Environment.production:
        return 'Tene';
    }
  }

  // Cache configuration
  static Duration get cacheDuration {
    switch (environment) {
      case Environment.development:
        return const Duration(minutes: 5);
      case Environment.staging:
        return const Duration(minutes: 15);
      case Environment.production:
        return const Duration(hours: 1);
    }
  }
}
