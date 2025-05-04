import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/google_link_screen.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
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
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final phoneNumber = _formatPhoneNumber(_phoneController.text.trim());

    try {
      await ref
          .read(authServiceProvider)
          .verifyPhoneNumber(
            phoneNumber: phoneNumber,
            onVerificationCompleted: (PhoneAuthCredential credential) async {
              // Auto-verification completed (Android only)
              await _signInWithCredential(credential);
            },
            onVerificationFailed: (FirebaseAuthException e) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Verification failed: ${e.message}';
              });
            },
            onCodeSent: (String verificationId, int? resendToken) {
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
            onCodeAutoRetrievalTimeout: (String verificationId) {
              setState(() {
                _verificationId = verificationId;
              });
            },
          );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error sending verification code: $e';
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await _signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid verification code';
      });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await ref.read(authServiceProvider).signInWithPhoneAuthCredential(credential);

      if (result.user != null) {
        if (mounted) {
          // After phone verification, navigate to link Google account
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (context) => const GoogleLinkScreen()));
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign in failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'First, let\'s verify your phone number',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'Enter the verification code sent to your phone'
                  : 'We will send you a one-time verification code',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

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
                        ? const CircularProgressIndicator.adaptive()
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
                    _isLoading ? const CircularProgressIndicator.adaptive() : const Text('Verify'),
              ),
              TextButton(
                onPressed: _isLoading ? null : _verifyPhone,
                child: const Text('Resend Code'),
              ),
            ],

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
