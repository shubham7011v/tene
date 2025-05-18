import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  // Get contact name from phone number
  Future<String> getContactNameFromPhone(String phoneNumber) async {
    try {
      // Check if we have contact permission
      final status = await Permission.contacts.status;
      if (status != PermissionStatus.granted) {
        return phoneNumber; // Return phone number if no permission
      }

      // Get all contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      // Find contact with matching phone number
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          // Normalize phone numbers for comparison
          final normalizedContactPhone = _normalizePhoneNumber(phone.number);
          final normalizedSearchPhone = _normalizePhoneNumber(phoneNumber);

          if (normalizedContactPhone.contains(normalizedSearchPhone) ||
              normalizedSearchPhone.contains(normalizedContactPhone)) {
            return contact.displayName;
          }
        }
      }

      return phoneNumber; // Return phone number if no match found
    } catch (e) {
      print('Error getting contact name: $e');
      return phoneNumber; // Return phone number on error
    }
  }

  // Normalize phone number by removing non-digit characters
  String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}
