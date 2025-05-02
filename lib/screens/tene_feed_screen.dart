import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/models/tene_model.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/receive_tene_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tene/models/mood_data.dart';

class TeneFeedScreen extends ConsumerWidget {
  const TeneFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodData = ref.watch(currentMoodDataProvider);
    final tenesAsync = ref.watch(unviewedTenesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tenes'),
        backgroundColor: moodData.primaryColor,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              moodData.primaryColor.withAlpha(40),
              moodData.primaryColor.withAlpha(100),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            
            // Calculate responsive dimensions
            final verticalPadding = maxHeight * 0.02;
            final horizontalPadding = maxWidth * 0.03;
            final buttonHeight = maxHeight * 0.06;
            final fontSize = maxWidth * 0.04;
            final titleSize = maxWidth * 0.05;
            final iconSize = maxWidth * 0.12;
            
            return tenesAsync.when(
              data: (tenes) {
                if (tenes.isEmpty) {
                  return _buildEmptyState(
                    context,
                    moodData,
                    iconSize: iconSize,
                    titleSize: titleSize,
                    fontSize: fontSize,
                    buttonHeight: buttonHeight,
                  );
                }
                return _buildTeneList(
                  context,
                  ref,
                  tenes,
                  moodData,
                  verticalPadding: verticalPadding,
                  horizontalPadding: horizontalPadding,
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(moodData.secondaryColor),
                  backgroundColor: moodData.primaryColor.withAlpha(51),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: EdgeInsets.all(maxWidth * 0.06),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: moodData.secondaryColor,
                        size: iconSize,
                      ),
                      SizedBox(height: verticalPadding),
                      Text(
                        'Error loading Tenes',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: moodData.secondaryColor,
                        ),
                      ),
                      SizedBox(height: verticalPadding * 0.5),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: moodData.secondaryColor,
                          fontSize: fontSize,
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(unviewedTenesProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: moodData.secondaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size(maxWidth * 0.4, buttonHeight),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  // Build empty state when no Tenes are available
  Widget _buildEmptyState(
    BuildContext context,
    MoodData moodData, {
    required double iconSize,
    required double titleSize,
    required double fontSize,
    required double buttonHeight,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mood,
              size: iconSize,
              color: moodData.secondaryColor.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'No vibes right now',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: moodData.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'When friends send you Tenes, they will appear here',
              style: TextStyle(
                fontSize: fontSize,
                color: moodData.secondaryColor.withAlpha(220),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Return to home screen
              },
              icon: const Icon(Icons.send),
              label: const Text('Send a Tene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: moodData.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: Size(200, buttonHeight),
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
    List<TeneModel> tenes, 
    MoodData moodData, {
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding * 2.5,
        horizontal: horizontalPadding * 2
      ),
      itemCount: tenes.length,
      itemBuilder: (context, index) {
        final tene = tenes[index];
        return _buildTeneCard(context, ref, tene, moodData);
      },
    );
  }

  // Build individual Tene card
  Widget _buildTeneCard(
    BuildContext context, 
    WidgetRef ref, 
    TeneModel tene, 
    MoodData moodData
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(selectedTeneProvider.notifier).state = tene;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ReceiveTeneScreen(tene: tene),
            ),
          );
        },
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
                    tene.moodEmoji,
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
                      tene.senderName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: moodData.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sent ${timeago.format(tene.timestamp)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (tene.gifUrl != null && tene.gifUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: moodData.primaryColor.withAlpha(100),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: tene.gifUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: moodData.primaryColor.withAlpha(30),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
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
} 