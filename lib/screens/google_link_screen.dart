import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/home_screen.dart';
import 'package:tene/utils/sign_in_config.dart';

class GoogleLinkScreen extends ConsumerStatefulWidget {
  const GoogleLinkScreen({super.key});

  @override
  ConsumerState<GoogleLinkScreen> createState() => _GoogleLinkScreenState();
}

class _GoogleLinkScreenState extends ConsumerState<GoogleLinkScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _linkWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await ref.read(authServiceProvider).linkWithGoogle();

      // If null, the sign-in was cancelled by the user
      if (userCredential == null) {
        setState(() {
          _isLoading = false;
          // Don't show error for user cancellation
        });
        return;
      }

      if (mounted) {
        // Navigate to home screen after successful linking
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
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
            content: Text('Account linking failed: $errorMessage'),
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
        title: const Text('Link Google Account'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(Icons.link, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Link Your Google Account',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Explanation
                Text(
                  'Your phone number has been verified! Now link your Google account for faster sign-in next time.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Google Link Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _linkWithGoogle,
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
                  icon:
                      _isLoading
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
                  label:
                      _isLoading
                          ? const Text('Linking...')
                          : const Text(
                            'Link Google Account',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                ),

                const SizedBox(height: 16),

                // Skip option
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                            );
                          },
                  child: const Text('Skip for now'),
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
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
