import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/services/tene_service.dart' hide allPairTenesProvider;
import 'package:tene/providers/providers.dart';
import 'package:tene/providers/tene_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tene/models/mood_data.dart';

class TeneFeedScreen extends ConsumerWidget {
  const TeneFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodData = ref.watch(currentMoodDataProvider);
    final tenesAsync = ref.watch(allPairTenesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Tenes'), backgroundColor: moodData.primaryColor),
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
                        onPressed: () => ref.invalidate(allPairTenesProvider),
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTeneDetailsDialog(context, ref, tene, moodData),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mood emoji
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: moodData.primaryColor.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    moodMap[tene.vibeType]?.emoji ?? '😊',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Tene details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${tene.senderId}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: moodData.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sent ${timeago.format(tene.sentAt)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (tene.gifUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: moodData.primaryColor.withAlpha(100)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: tene.gifUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: moodData.primaryColor.withAlpha(30),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: moodData.primaryColor.withAlpha(30),
                                  child: const Icon(Icons.broken_image),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right arrow
              Icon(
                Icons.arrow_forward_ios,
                color: moodData.secondaryColor.withAlpha(150),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show Tene details in a dialog
  void _showTeneDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    TeneData tene,
    MoodData moodData,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with mood color
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: moodData.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tene from User ${tene.senderId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // GIF
                  if (tene.gifUrl.isNotEmpty)
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: CachedNetworkImage(imageUrl: tene.gifUrl, fit: BoxFit.cover),
                    ),

                  // Mood info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          moodMap[tene.vibeType]?.emoji ?? '😊',
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Feeling ${moodMap[tene.vibeType]?.name ?? "Happy"}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: moodData.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sent ${timeago.format(tene.sentAt)}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: moodData.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
