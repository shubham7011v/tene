import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/providers/auth_providers.dart';
import 'package:tene/providers/tene_providers.dart' as tene_providers;
import 'package:tene/screens/home_screen.dart';
import 'package:tene/widgets/tene_status_dialog.dart';

// State provider for contact search query
final contactSearchQueryProvider = StateProvider<String>((ref) => '');

// State provider for contact permission status
final contactPermissionProvider = StateProvider<PermissionStatus>((ref) {
  return PermissionStatus.denied;
});

// Provider for filtered contacts based on search query
final filteredContactsProvider = FutureProvider<List<Contact>>((ref) async {
  final searchQuery = ref.watch(contactSearchQueryProvider).toLowerCase();

  // Get all contacts
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
    if (status != PermissionStatus.granted) {
      await Permission.contacts.request();
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
      final result = await ref
          .read(tene_providers.teneServiceProvider)
          .sendTene(
            toPhone: _selectedPhone!,
            vibeType: ref.read(currentMoodProvider),
            gifUrl: widget.gifUrl,
          );

      if (mounted) {
        // Show the appropriate dialog based on the result
        showTeneStatusDialog(
          context,
          result,
          onDismiss: () {
            if (result.success) {
              // If successful, return to home screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            } else {
              // If failed, just close the dialog and stay on contact picker
              setState(() {
                _isSending = false;
              });
            }
          },
        );
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
                  'Who do you want to send your tene to?',
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
