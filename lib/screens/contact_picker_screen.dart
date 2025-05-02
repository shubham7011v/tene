import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/models/mood_data.dart';

/// Create a TeneService class to handle sending Tenes
class TeneService {
  static Future<bool> sendTene({
    required String phoneNumber,
    required String moodName,
    required String gifUrl,
  }) async {
    // In a real app, this would send data to a backend
    // For now, we'll just simulate a successful send with a delay
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

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
  final contacts = await FlutterContacts.getContacts(
    withProperties: true, 
    withThumbnail: false,
  );
  
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
  const ContactPickerScreen({super.key});

  @override
  ConsumerState<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Check if we have contacts permission
  Future<void> _checkPermission() async {
    final status = await Permission.contacts.status;
    ref.read(contactPermissionProvider.notifier).state = status;
    
    // Request permission if not granted
    if (status != PermissionStatus.granted) {
      await _requestPermission();
    }
  }
  
  // Request contacts permission
  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    ref.read(contactPermissionProvider.notifier).state = status;
  }
  
  // Extract the Tene sending logic to a new method
  Future<void> _sendTeneToContact(String phoneNumber, MoodData mood, String? gifUrl) async {
    if (!mounted) return;
    
    // Show loading indicator
    _showLoadingDialog(mood);
    
    // Call service to send Tene
    await TeneService.sendTene(
      phoneNumber: phoneNumber,
      moodName: mood.name,
      gifUrl: gifUrl ?? '',
    );
    
    // Check if still mounted before UI updates
    if (!mounted) return;
    
    // Close loading dialog and show result
    Navigator.of(context).pop();
    
    // Show success
    _showSuccessDialog(phoneNumber, mood);
  }

  // Show loading dialog
  void _showLoadingDialog(MoodData mood) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(mood.secondaryColor),
            ),
            const SizedBox(height: 16),
            const Text('Sending your Tene...'),
          ],
        ),
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog(String phoneNumber, MoodData mood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tene Sent!'),
        content: Text('Your mood "${mood.name}" ${mood.emoji} was sent to $phoneNumber with a GIF!'),
        backgroundColor: mood.primaryColor.withAlpha(240),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate back to the home screen
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final permissionStatus = ref.watch(contactPermissionProvider);
    final searchQuery = ref.watch(contactSearchQueryProvider);
    final contactsAsync = ref.watch(filteredContactsProvider);
    final moodData = ref.watch(currentMoodDataProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
        backgroundColor: moodData.primaryColor,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                fillColor: moodData.primaryColor.withAlpha(26),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(contactSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(contactSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          
          // Permission handling and contact list
          Expanded(
            child: Builder(
              builder: (context) {
                // Handle permission denied/restricted cases
                if (permissionStatus == PermissionStatus.denied ||
                    permissionStatus == PermissionStatus.restricted ||
                    permissionStatus == PermissionStatus.permanentlyDenied) {
                  return _buildPermissionDenied(moodData);
                }
                
                // Handle contact list
                return contactsAsync.when(
                  data: (contacts) {
                    if (contacts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts,
                              size: 64,
                              color: moodData.secondaryColor.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No contacts found with phone numbers'
                                  : 'No contacts match "$searchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                color: moodData.secondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final hasPhoneNumber = contact.phones.isNotEmpty;
                        final phoneNumber = hasPhoneNumber 
                            ? contact.phones.first.number 
                            : '';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: moodData.primaryColor,
                            child: Text(
                              _getInitials(contact.displayName),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(phoneNumber),
                          onTap: () {
                            // Save the selected contact
                            ref.read(selectedContactProvider.notifier).state = phoneNumber;
                            
                            // Get the mood and GIF
                            final mood = ref.read(currentMoodDataProvider);
                            final gifUrl = ref.read(selectedGifProvider);
                            
                            // Send the Tene with proper context handling
                            _sendTeneToContact(phoneNumber, mood, gifUrl);
                          },
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            moodData.secondaryColor,
                          ),
                          backgroundColor: moodData.primaryColor.withAlpha(51),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading contacts...',
                          style: TextStyle(
                            color: moodData.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: moodData.secondaryColor,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading contacts: ${error.toString()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: moodData.secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(filteredContactsProvider);
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Build UI for when permission is denied
  Widget _buildPermissionDenied(MoodData moodData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts,
              size: 72,
              color: moodData.secondaryColor.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: moodData.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To select a contact, we need permission to access your contacts. '
              'Please grant this permission in your device settings.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.contacts.request();
                ref.read(contactPermissionProvider.notifier).state = status;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: moodData.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Grant Permission'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: Text(
                'Open Settings',
                style: TextStyle(color: moodData.secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to get initials from a name
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
} 