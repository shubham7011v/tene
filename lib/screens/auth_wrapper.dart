import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/screens/login_screen.dart';
import 'package:tene/screens/home_screen.dart';
import 'package:tene/providers/providers.dart';

/// AuthWrapper checks the authentication state and redirects to the appropriate screen
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state changes
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        // If user is logged in, show HomeScreen
        if (user != null) {
          return const HomeScreen();
        }
        // If user is not logged in, show LoginScreen
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
} 