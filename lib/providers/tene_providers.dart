import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/services/tene_service.dart';
import 'package:tene/providers/auth_providers.dart';
import 'package:flutter/widgets.dart';

/// Provider for getting the currently authenticated user ID
final userIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid ?? '';
});

/// Provider for the Tene Service
final teneServiceProvider = Provider<TeneService>((ref) {
  final service = TeneService();

  // Initialize sent status tracking
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.initializeSentStatusTracking();
  });

  return service;
});

/// Provider for a function that views a Tene
final viewTeneProvider = Provider.family<void, String>((ref, pairId) {
  final teneService = ref.watch(teneServiceProvider);
  teneService.markTeneViewed(pairId);
});

/// Provider for observing incoming Tenes from a specific phone
final incomingTenesProvider = StreamProvider.family<List<TeneData>, String>((ref, phone) {
  final teneService = ref.watch(teneServiceProvider);

  // Filter received Tenes by the sender's phone number
  return teneService.getReceivedTenes().map((tenes) {
    return tenes.where((tene) => tene.senderPhone == phone).toList();
  });
});

/// Provider for checking if we can send a Tene to a contact
final canSendTeneToContactProvider = FutureProvider.family<bool, String>((ref, contactPhone) async {
  final teneService = ref.watch(teneServiceProvider);
  // We can send a Tene if we haven't already sent one to this contact
  return !(await teneService.hasSentTeneToContact(contactPhone));
});

/// Provider for a function that sends a Tene
final sendTeneProvider = Provider<
  Future<SendTeneResult> Function({
    required String toPhone,
    required String vibeType,
    required String gifUrl,
  })
>((ref) {
  final teneService = ref.watch(teneServiceProvider);

  return ({required String toPhone, required String vibeType, required String gifUrl}) async {
    return teneService.sendTene(toPhone: toPhone, vibeType: vibeType, gifUrl: gifUrl);
  };
});

/// Provider for received Tenes
final receivedTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getReceivedTenes();
});

/// Provider for sent Tenes
final sentTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getSentTenes();
});

/// Provider for unviewed Tenes
final unviewedTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getUnviewedTenes();
});

/// Provider for viewed Tenes
final viewedTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getReceivedTenes().map((tenes) => tenes.where((tene) => tene.viewed).toList());
});
