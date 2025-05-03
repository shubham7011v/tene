import 'package:flutter/material.dart';
import 'package:tene/config/environment.dart';

/// A widget that displays a banner showing the current environment (DEV/PROD)
/// Only shown in development mode
class EnvironmentBanner extends StatelessWidget {
  /// The child widget to wrap with the environment banner
  final Widget child;
  
  /// Whether to force show the banner even in production
  final bool alwaysShow;
  
  /// Create an environment banner
  const EnvironmentBanner({
    Key? key,
    required this.child,
    this.alwaysShow = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Only show the banner in development by default
    if (Environment.isProduction && !alwaysShow) {
      return child;
    }
    
    // Use a banner with the environment name
    return Banner(
      message: Environment.flavor.toUpperCase(),
      location: BannerLocation.topEnd,
      color: _getBannerColor(),
      child: child,
    );
  }
  
  /// Get the banner color based on the environment
  Color _getBannerColor() {
    if (Environment.isProduction) {
      return Colors.green.shade800; // Dark green for production
    } else {
      return Colors.orange.shade800; // Orange for development
    }
  }
} 