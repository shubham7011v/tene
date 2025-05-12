import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/screens/home_screen.dart';

class PhoneLinkScreen extends ConsumerStatefulWidget {
  const PhoneLinkScreen({super.key});

  @override
  ConsumerState<PhoneLinkScreen> createState() => _PhoneLinkScreenState();
}

class _PhoneLinkScreenState extends ConsumerState<PhoneLinkScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String _verificationId = '';
  String _errorMessage = '';
  int? _resendToken;
  bool _isCountryDropdownOpen = false;
  List<Map<String, String>> _filteredCountryCodes = [];

  // Country code selection
  String _selectedCountryCode = '+91'; // Default to India
  String _selectedCountryName = '🇮🇳 India (+91)';

  // List of country codes with flags
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'name': '🇺🇸 United States (+1)'},
    {'code': '+44', 'name': '🇬🇧 United Kingdom (+44)'},
    {'code': '+91', 'name': '🇮🇳 India (+91)'},
    {'code': '+86', 'name': '🇨🇳 China (+86)'},
    {'code': '+81', 'name': '🇯🇵 Japan (+81)'},
    {'code': '+82', 'name': '🇰🇷 South Korea (+82)'},
    {'code': '+49', 'name': '🇩🇪 Germany (+49)'},
    {'code': '+33', 'name': '🇫🇷 France (+33)'},
    {'code': '+39', 'name': '🇮🇹 Italy (+39)'},
    {'code': '+7', 'name': '🇷🇺 Russia (+7)'},
    {'code': '+55', 'name': '🇧🇷 Brazil (+55)'},
    {'code': '+52', 'name': '🇲🇽 Mexico (+52)'},
    {'code': '+61', 'name': '🇦🇺 Australia (+61)'},
    {'code': '+64', 'name': '🇳🇿 New Zealand (+64)'},
    {'code': '+65', 'name': '🇸🇬 Singapore (+65)'},
    {'code': '+34', 'name': '🇪🇸 Spain (+34)'},
    {'code': '+1', 'name': '🇨🇦 Canada (+1)'},
    {'code': '+971', 'name': '🇦🇪 UAE (+971)'},
    {'code': '+966', 'name': '🇸🇦 Saudi Arabia (+966)'},
    {'code': '+20', 'name': '🇪🇬 Egypt (+20)'},
    {'code': '+27', 'name': '🇿🇦 South Africa (+27)'},
    {'code': '+234', 'name': '🇳🇬 Nigeria (+234)'},
    {'code': '+254', 'name': '🇰🇪 Kenya (+254)'},
    {'code': '+60', 'name': '🇲🇾 Malaysia (+60)'},
    {'code': '+66', 'name': '🇹🇭 Thailand (+66)'},
    {'code': '+63', 'name': '🇵🇭 Philippines (+63)'},
    {'code': '+62', 'name': '🇮🇩 Indonesia (+62)'},
    {'code': '+84', 'name': '🇻🇳 Vietnam (+84)'},
    {'code': '+90', 'name': '🇹🇷 Turkey (+90)'},
    {'code': '+48', 'name': '🇵🇱 Poland (+48)'},
    {'code': '+351', 'name': '🇵🇹 Portugal (+351)'},
    {'code': '+31', 'name': '🇳🇱 Netherlands (+31)'},
    {'code': '+32', 'name': '🇧🇪 Belgium (+32)'},
    {'code': '+41', 'name': '🇨🇭 Switzerland (+41)'},
    {'code': '+46', 'name': '🇸🇪 Sweden (+46)'},
    {'code': '+47', 'name': '🇳🇴 Norway (+47)'},
    {'code': '+45', 'name': '🇩🇰 Denmark (+45)'},
    {'code': '+358', 'name': '🇫🇮 Finland (+358)'},
    {'code': '+30', 'name': '🇬🇷 Greece (+30)'},
    {'code': '+36', 'name': '🇭🇺 Hungary (+36)'},
    {'code': '+420', 'name': '🇨🇿 Czech Republic (+420)'},
    {'code': '+43', 'name': '🇦🇹 Austria (+43)'},
    {'code': '+353', 'name': '🇮🇪 Ireland (+353)'},
    {'code': '+972', 'name': '🇮🇱 Israel (+972)'},
    {'code': '+962', 'name': '🇯🇴 Jordan (+962)'},
    {'code': '+961', 'name': '🇱🇧 Lebanon (+961)'},
    {'code': '+880', 'name': '🇧🇩 Bangladesh (+880)'},
    {'code': '+94', 'name': '🇱🇰 Sri Lanka (+94)'},
    {'code': '+92', 'name': '🇵🇰 Pakistan (+92)'},
    {'code': '+977', 'name': '🇳🇵 Nepal (+977)'},
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountryCodes = List.from(_countryCodes);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountryCodes = List.from(_countryCodes);
      } else {
        _filteredCountryCodes =
            _countryCodes
                .where(
                  (country) =>
                      country['name']!.toLowerCase().contains(query.toLowerCase()) ||
                      country['code']!.contains(query),
                )
                .toList();
      }
    });
  }

  // Format phone number with country code
  String _formatPhoneNumber(String phone) {
    // Clean the phone number of any non-digit characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If the phone already has a country code (starts with +), return it as is
    if (cleanPhone.startsWith('+')) {
      return cleanPhone;
    }

    // Otherwise, add the selected country code
    return _selectedCountryCode + cleanPhone;
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'No user is signed in';
        });
        return;
      }

      await user.linkWithCredential(credential);
      await FirebaseAuth.instance.currentUser?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      final phoneNumber =
          refreshedUser?.phoneNumber ?? _formatPhoneNumber(_phoneController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number linked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

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
      debugPrint('Detailed phone linking error: $e');
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

              // Show OTP input field or phone number input field
              if (_otpSent) ...[
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    hintText: 'Enter the 6-digit code',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                    fillColor: theme.colorScheme.surface.withOpacity(0.8),
                    filled: true,
                    labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.security, color: theme.colorScheme.primary),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.4),
                    disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.6),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Verify Code',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                ),
              ] else ...[
                // Country code selector with search
                InkWell(
                  onTap: () {
                    setState(() {
                      _isCountryDropdownOpen = !_isCountryDropdownOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface.withOpacity(0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCountryName,
                            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                          ),
                        ),
                        Icon(
                          _isCountryDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Country dropdown when open
                if (_isCountryDropdownOpen) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search country...',
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                            ),
                            fillColor: theme.colorScheme.surface,
                            filled: true,
                          ),
                          onChanged: _filterCountries,
                        ),
                        const SizedBox(height: 8),

                        // Country list
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _filteredCountryCodes.length,
                            itemBuilder: (context, index) {
                              final country = _filteredCountryCodes[index];
                              final isSelected = country['code'] == _selectedCountryCode;

                              return ListTile(
                                title: Text(
                                  country['name']!,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color:
                                        isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                  ),
                                ),
                                tileColor:
                                    isSelected
                                        ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                                        : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCountryCode = country['code']!;
                                    _selectedCountryName = country['name']!;
                                    _isCountryDropdownOpen = false;
                                    _searchController.clear();
                                    _filteredCountryCodes = List.from(_countryCodes);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Phone number field
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                    fillColor: theme.colorScheme.surface.withOpacity(0.8),
                    filled: true,
                    labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPhone,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.4),
                    disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.6),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Send Verification Code',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                ),
              ],

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // Display an important note instead of a skip button (for debug only)
              if (_otpSent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Important: You must verify your phone number before continuing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
