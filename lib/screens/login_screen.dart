import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/home_screen.dart';
import 'package:tene/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _codeSent = false;
  bool _isVerifying = false;
  bool _isVerifyingOTP = false;
  String? _verificationId;
  int? _resendToken;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Format phone number to include country code if missing
  String _formatPhoneNumber(String number) {
    // Remove any whitespace
    number = number.replaceAll(RegExp(r'\s+'), '');
    
    // If doesn't start with +, add +1 (US) as default
    if (!number.startsWith('+')) {
      number = '+1$number';
    }
    
    return number;
  }

  // Handle verification code sent
  void _onCodeSent(String verificationId, int? resendToken) {
    setState(() {
      _codeSent = true;
      _isLoading = false;
      _verificationId = verificationId;
      _resendToken = resendToken;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code sent to your phone'),
      ),
    );
  }

  // Handle verification completed
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Sign in with the credential
      await ref.read(authServiceProvider).signInWithCredential(credential);
      
      // Navigate to home screen if mounted
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    }
  }

  // Handle verification failed
  void _onVerificationFailed(FirebaseAuthException e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Verification failed: ${e.message}';
    });
  }

  // Handle auto-retrieval timeout
  void _onCodeAutoRetrievalTimeout(String verificationId) {
    // No need to do anything
  }

  // Send verification code
  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final formattedPhoneNumber = _formatPhoneNumber(_phoneController.text);
      
      await ref.read(authServiceProvider).verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        onVerificationCompleted: _onVerificationCompleted,
        onVerificationFailed: _onVerificationFailed,
        onCodeSent: _onCodeSent,
        onCodeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send code: ${e.toString()}';
      });
    }
  }

  // Verify OTP code
  Future<void> _verifyCode() async {
    if (_otpController.text.length < 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Verify OTP
      await ref.read(authServiceProvider).verifyOTP(_otpController.text);
      
      // Create or update user profile
      await ref.read(authServiceProvider).createOrUpdateUserProfile(
        phoneNumber: _phoneController.text,
      );
      
      // Navigate to home screen if mounted
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyPhoneNumber() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification completed
          await _signInWithCredential(credential);
        },
        onVerificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isVerifying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        onCodeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isVerifying = false;
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
        },
        onCodeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithCredential(credential);
      
      // Create or update user profile
      await authService.createOrUpdateUserProfile(
        phoneNumber: _phoneController.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code')),
      );
      return;
    }

    setState(() {
      _isVerifyingOTP = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyOTP(_otpController.text);
    } catch (e) {
      setState(() {
        _isVerifyingOTP = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
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
            child: Form(
              key: _formKey,
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
                  
                  // Phone number input
                  if (_verificationId == null) ...[
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '(123) 456-7890',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyPhoneNumber,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isVerifying
                          ? const CircularProgressIndicator()
                          : const Text('Send Verification Code'),
                    ),
                  ],
                  
                  // OTP input
                  if (_verificationId != null) ...[
                    TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        hintText: '6-digit code',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isVerifyingOTP ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isVerifyingOTP
                          ? const CircularProgressIndicator()
                          : const Text('Verify Code'),
                    ),
                    TextButton(
                      onPressed: _isVerifying ? null : _verifyPhoneNumber,
                      child: const Text('Resend Code'),
                    ),
                  ],
                  
                  // Error message
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 