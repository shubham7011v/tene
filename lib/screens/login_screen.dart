import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/home_screen.dart';
import 'package:tene/utils/sign_in_config.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Check if Google Play Services are available
    _checkPlayServices();
  }

  Future<void> _checkPlayServices() async {
    final hasGooglePlay = await SignInConfig.checkGooglePlayServices();
    if (!hasGooglePlay && mounted) {
      setState(() {
        _errorMessage = 'Google Play Services are required but not available';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await ref.read(authServiceProvider).signInWithGoogle();
      
      // If null, the sign-in was cancelled by the user
      if (userCredential == null) {
        setState(() {
          _isLoading = false;
          // Don't show error for user cancellation
        });
        return;
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      // Use the error formatter
      final errorMessage = SignInConfig.formatSignInError(e);
      
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
      
      // Show a snackbar with error details
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tene Login'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Text(
                  'Tene',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Share your mood with friends',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Google Sign In Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                          ),
                        )
                      : Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to a Text 'G' if image loading fails
                            return Container(
                              height: 24,
                              width: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                  label: _isLoading
                      ? const Text('Signing in...')
                      : const Text('Sign in with Google', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                
                // Error message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                // Help text
                Text(
                  'Having trouble signing in? Make sure you have Google Play Services installed and up to date.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 