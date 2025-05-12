import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/providers/tene_providers.dart';
import 'package:tene/models/tene_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tene/screens/receive_tene_screen.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/services/tene_service.dart';
import 'dart:math' as math;

class AllTenesScreen extends ConsumerWidget {
  const AllTenesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenesAsync = ref.watch(allPairTenesProvider);
    final moodData = ref.watch(currentMoodDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Vibes'),
        backgroundColor: moodData.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: tenesAsync.when(
        data: (tenes) {
          if (tenes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: moodData.secondaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No vibes yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A6D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When friends send you vibes, they will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF5A7A99), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tenes.length,
            itemBuilder: (context, index) {
              final tene = tenes[index];
              return _buildTeneCard(context, tene, moodData);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) =>
                Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildTeneCard(BuildContext context, TeneData tene, MoodData moodData) {
    // Get mood color and emoji
    final moodColor = moodMap[tene.vibeType]?.primaryColor ?? Colors.purple;
    final emoji = moodMap[tene.vibeType]?.emoji ?? '😊';

    // Format sender display
    String senderDisplay = 'Someone';
    if (tene.senderId.isNotEmpty) {
      final parts = tene.senderId.split('@');
      if (parts.isNotEmpty) {
        senderDisplay = parts[0];
        if (senderDisplay.startsWith('+')) {
          senderDisplay = "***${senderDisplay.substring(math.max(0, senderDisplay.length - 4))}";
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.7),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Convert TeneData to TeneModel
          final teneModel = TeneModel(
            id: tene.docId,
            senderId: tene.senderId,
            receiverId: tene.receiverId,
            vibeType: tene.vibeType,
            gifUrl: tene.gifUrl,
            sentAt: tene.sentAt,
            viewed: tene.viewed,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReceiveTeneScreen(tene: teneModel)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Sender avatar/emoji
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: moodColor.withOpacity(0.2),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),

              // Tene content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$senderDisplay sent you a Tene',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4A6D),
                      ),
                    ),
                    Text(
                      timeago.format(tene.sentAt),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              // View status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tene.viewed ? Colors.grey : Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF6A8CAF), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
