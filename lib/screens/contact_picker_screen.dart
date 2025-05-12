import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/providers/auth_providers.dart';
import 'package:tene/screens/home_screen.dart';

// State provider for contact search query
final contactSearchQueryProvider = StateProvider<String>((ref) => '');

// State provider for contact permission status
final contactPermissionProvider = StateProvider<PermissionStatus>((ref) {
  return PermissionStatus.denied;
});

// Provider for filtered contacts based on search query
final filteredContactsProvider = FutureProvider<List<Contact>>((ref) async {
  final permissionStatus = ref.watch(contactPermissionProvider);
  final searchQuery = ref.watch(contactSearchQueryProvider).toLowerCase();

  if (permissionStatus != PermissionStatus.granted) {
    return [];
  }

  // Fetch all contacts with phone numbers
  final contacts = await FlutterContacts.getContacts(withProperties: true, withThumbnail: false);

  // Filter contacts based on search query
  if (searchQuery.isEmpty) {
    return contacts.where((contact) => contact.phones.isNotEmpty).toList();
  } else {
    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      return name.contains(searchQuery) && contact.phones.isNotEmpty;
    }).toList();
  }
});

class ContactPickerScreen extends ConsumerStatefulWidget {
  final String gifUrl;

  const ContactPickerScreen({super.key, required this.gifUrl});

  @override
  ConsumerState<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  bool _isSending = false;
  String? _selectedPhone;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkContactPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Check and request contact permission
  Future<void> _checkContactPermission() async {
    final status = await Permission.contacts.status;
    ref.read(contactPermissionProvider.notifier).state = status;

    if (status != PermissionStatus.granted) {
      final result = await Permission.contacts.request();
      ref.read(contactPermissionProvider.notifier).state = result;
    }
  }

  // Handle contact selection
  void _selectContact(String phone) {
    setState(() {
      _selectedPhone = phone;
      _errorMessage = null;
    });
  }

  // Update search query
  void _updateSearchQuery(String query) {
    ref.read(contactSearchQueryProvider.notifier).state = query;
  }

  // Send Tene using phone number
  Future<void> _sendTene() async {
    if (_selectedPhone == null) {
      setState(() {
        _errorMessage = 'Please select a contact';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      // Check if user is logged in
      final authState = ref.read(authStateProvider).value;
      if (authState == null) {
        setState(() {
          _errorMessage = 'You must be logged in to send a Tene';
          _isSending = false;
        });
        return;
      }

      // Ensure user has a phone number
      if (authState.phoneNumber == null || authState.phoneNumber!.isEmpty) {
        setState(() {
          _errorMessage = 'Your account must have a phone number to send Tenes';
          _isSending = false;
        });
        return;
      }

      // Send the Tene using TeneService
      await ref
          .read(teneServiceProvider)
          .sendTene(
            toPhone: _selectedPhone!,
            vibeType: ref.read(currentMoodProvider),
            gifUrl: widget.gifUrl,
          );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isSending = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Tene Sent!'),
            content: const Text('Your vibe has been sent successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Return to home screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('GREAT!'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodData = ref.watch(currentMoodDataProvider);
    final permissionStatus = ref.watch(contactPermissionProvider);
    final contactsAsync = ref.watch(filteredContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Contact'), backgroundColor: moodData.primaryColor),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  moodData.primaryColor.withAlpha(40),
                  moodData.secondaryColor.withAlpha(20),
                ],
              ),
            ),
          ),

          // Content
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Who do you want to send your vibe to?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: moodData.secondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _updateSearchQuery,
                ),
              ),

              const SizedBox(height: 16),

              // Permission status
              if (permissionStatus != PermissionStatus.granted)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.contact_phone, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Contact permission required',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please grant permission to access your contacts',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkContactPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: moodData.secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Grant Permission'),
                      ),
                    ],
                  ),
                ),

              // Contacts list
              Expanded(
                child: contactsAsync.when(
                  data: (contacts) {
                    if (contacts.isEmpty) {
                      return const Center(child: Text('No contacts found'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

                        return _buildContactItem(phone, contact.displayName, phone);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text('Error: $error')),
                ),
              ),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Send button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendTene,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moodData.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child:
                      _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SEND TENE', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String id, String name, String phoneNumber) {
    final isSelected = _selectedPhone == id;
    final moodData = ref.watch(currentMoodDataProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: moodData.secondaryColor, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectContact(id),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: moodData.primaryColor.withAlpha(50),
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: TextStyle(color: moodData.secondaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(phoneNumber, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ),
              isSelected
                  ? Icon(Icons.check_circle, color: moodData.secondaryColor)
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
