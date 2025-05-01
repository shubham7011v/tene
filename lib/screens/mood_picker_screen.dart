import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/giphy_picker_screen.dart';

class MoodPickerScreen extends ConsumerWidget {
  const MoodPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMoodId = ref.watch(currentMoodProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Mood'),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: moodMap.length,
                itemBuilder: (context, index) {
                  final moodEntry = moodMap.entries.elementAt(index);
                  final mood = moodEntry.value;
                  final isSelected = moodEntry.key == currentMoodId;
                  
                  return MoodButton(
                    mood: mood,
                    isSelected: isSelected,
                    onTap: () {
                      // Update the mood provider
                      ref.read(currentMoodProvider.notifier).state = moodEntry.key;
                      
                      // Navigate to GiphyPickerScreen instead of going back
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const GiphyPickerScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodButton extends StatelessWidget {
  final MoodData mood;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mood.primaryColor.withAlpha(179),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.secondaryColor.withAlpha(153),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ],
          border: isSelected
              ? Border.all(
                  color: mood.secondaryColor,
                  width: 3,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mood.emoji,
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 8),
            Text(
              mood.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 