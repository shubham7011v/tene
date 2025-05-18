import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/services/contact_service.dart';

// Provider for the contact service instance
final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

// Provider for looking up contact names by phone number
final contactNameProvider = FutureProvider.family<String, String>((ref, phoneNumber) async {
  final contactService = ref.watch(contactServiceProvider);
  return contactService.getContactNameFromPhone(phoneNumber);
});
