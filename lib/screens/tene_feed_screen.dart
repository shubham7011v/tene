import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/services/tene_service.dart' hide teneServiceProvider;
import 'package:tene/providers/providers.dart';
import 'package:tene/providers/tene_providers.dart' as tene_providers;
import 'package:tene/providers/contact_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tene/models/mood_data.dart';
import 'package:tene/screens/receive_tene_screen.dart';
import 'package:tene/models/tene_model.dart';

class TeneFeedScreen extends ConsumerWidget {
  const TeneFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodData = ref.watch(currentMoodDataProvider);
    final tenesAsync = ref.watch(tene_providers.allPairTenesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tenes'),
        backgroundColor: moodData.primaryColor,
        foregroundColor: Colors.black,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [moodData.primaryColor.withAlpha(40), moodData.primaryColor.withAlpha(100)],
          ),
        ),
        child: tenesAsync.when(
          data: (tenes) {
            if (tenes.isEmpty) {
              return _buildEmptyState(context, moodData);
            }
            return _buildTeneList(context, ref, tenes, moodData);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading Tenes: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(tene_providers.allPairTenesProvider),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  // Build empty state when no Tenes are available
  Widget _buildEmptyState(BuildContext context, MoodData moodData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mood, size: 64, color: moodData.secondaryColor.withAlpha(128)),
            const SizedBox(height: 24),
            Text(
              'No vibes right now',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: moodData.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'When friends send you Tenes, they will appear here',
              style: TextStyle(fontSize: 16, color: moodData.secondaryColor.withAlpha(220)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.send),
              label: const Text('Send a Tene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: moodData.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build list of Tenes
  Widget _buildTeneList(
    BuildContext context,
    WidgetRef ref,
    List<TeneData> tenes,
    MoodData moodData,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tenes.length,
      itemBuilder: (context, index) {
        final tene = tenes[index];
        return _buildTeneCard(context, ref, tene, moodData);
      },
    );
  }

  // Build individual Tene card
  Widget _buildTeneCard(BuildContext context, WidgetRef ref, TeneData tene, MoodData moodData) {
    final teneColor = moodMap[tene.vibeType] ?? moodMap['jhappi']!;
    final contactNameAsync = ref.watch(contactNameProvider(tene.senderPhone));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      color: Colors.white.withOpacity(0.7),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewTene(context, ref, tene),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mood emoji
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: teneColor.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(teneColor.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),

              // Tene details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact name from provider
                    contactNameAsync.when(
                      data:
                          (name) => Text(
                            'From $name',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D4A6D),
                            ),
                          ),
                      loading:
                          () => Text(
                            'Loading sender...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D4A6D),
                            ),
                          ),
                      error:
                          (_, __) => Text(
                            'From ${tene.senderPhone}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D4A6D),
                            ),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Feeling ${teneColor.name}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: teneColor.secondaryColor,
                      ),
                    ),
                    Text(
                      timeago.format(tene.sentAt),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // Right arrow
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF6A8CAF), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // View a Tene by opening the receive screen
  void _viewTene(BuildContext context, WidgetRef ref, TeneData tene) {
    // Mark the Tene as viewed
    ref.read(tene_providers.teneServiceProvider).markTeneViewed(tene.docId);

    // Convert TeneData to TeneModel
    final teneModel = TeneModel(
      id: tene.docId,
      senderId: tene.senderId,
      receiverId: '',
      vibeType: tene.vibeType,
      gifUrl: tene.gifUrl,
      sentAt: tene.sentAt,
      viewed: true,
    );

    // Navigate to the ReceiveTeneScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReceiveTeneScreen(tene: teneModel)),
    );
  }
}
