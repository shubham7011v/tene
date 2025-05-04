import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/home_screen.dart';

class PhoneLinkScreen extends ConsumerStatefulWidget {
  const PhoneLinkScreen({super.key});

  @override
  ConsumerState<PhoneLinkScreen> createState() => _PhoneLinkScreenState();
}

class _PhoneLinkScreenState extends ConsumerState<PhoneLinkScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String _verificationId = '';
  String _errorMessage = '';
  int? _resendToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Format phone number to ensure it has country code
  String _formatPhoneNumber(String phone) {
    // If the phone number doesn't start with +, add +1 (US) as default
    if (!phone.startsWith('+')) {
      return '+1$phone';
    }
    return phone;
  }

  Future<void> _verifyPhone() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final phoneNumber = _formatPhoneNumber(_phoneController.text.trim());

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await _linkWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'Verification failed: ${e.message}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _otpSent = true;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your phone'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error sending verification code: $e';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await _linkWithCredential(credential);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid verification code';
      });
    }
  }

  Future<void> _linkWithCredential(PhoneAuthCredential credential) async {
    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'No user is signed in';
        });
        return;
      }

      // Link the phone credential with the current user
      await user.linkWithCredential(credential);

      // Save the phone linked status
      final phoneNumber = _formatPhoneNumber(_phoneController.text.trim());
      await ref.read(authServiceProvider).setPhoneLinked(user.uid, phoneNumber);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number linked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Phone linking failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Phone Number'),
        // Prevent going back without linking phone
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon and title
              Icon(Icons.phone_android, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Link Your Phone Number',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _otpSent
                    ? 'Enter the verification code sent to your phone'
                    : 'We need to verify your phone number for additional security',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 (123) 456-7890',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPhone,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Send Verification Code'),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '123456',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.security),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Verify'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _verifyPhone,
                  child: const Text('Resend Code'),
                ),
              ],

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
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Allow user to skip for now, but warn them
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Skip Phone Verification?'),
                          content: const Text(
                            'Your account will be less secure without a linked phone number. You can link it later from your profile.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              },
                              child: const Text('SKIP ANYWAY'),
                            ),
                          ],
                        ),
                  );
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
