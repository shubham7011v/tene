import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/services/tene_service.dart';
import 'package:tene/providers/auth_providers.dart';

/// Provider for getting the currently authenticated user ID
final userIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid ?? '';
});

/// Provider for the Tene Service
final teneServiceProvider = Provider<TeneService>((ref) {
  return TeneService();
});

/// Stream provider for all pair Tenes
final allPairTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getReceivedTenes();
});

/// Provider for a function that views a Tene
final viewTeneProvider = Provider.family<void, String>((ref, pairId) {
  final teneService = ref.watch(teneServiceProvider);
  teneService.markTeneViewed(pairId);
});

/// Provider for observing incoming Tenes from a specific phone
final incomingTenesProvider = StreamProvider.family<TeneData, String>((ref, phone) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.observeIncomingTenes(otherPhone: phone);
});

/// Provider for a function that sends a Tene
final sendTeneProvider = Provider<
  Future<void> Function({required String toPhone, required String vibeType, required String gifUrl})
>((ref) {
  final teneService = ref.watch(teneServiceProvider);

  return ({required String toPhone, required String vibeType, required String gifUrl}) async {
    await teneService.sendTene(toPhone: toPhone, vibeType: vibeType, gifUrl: gifUrl);
  };
});
