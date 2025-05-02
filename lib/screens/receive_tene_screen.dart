import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/models/tene_model.dart';
import 'package:tene/providers/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:lottie/lottie.dart';

class ReceiveTeneScreen extends ConsumerStatefulWidget {
  final TeneModel tene;

  const ReceiveTeneScreen({super.key, required this.tene});

  @override
  ConsumerState<ReceiveTeneScreen> createState() => _ReceiveTeneScreenState();
}

class _ReceiveTeneScreenState extends ConsumerState<ReceiveTeneScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showThanks = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Mark the Tene as viewed when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsViewed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Mark the Tene as viewed in Firestore
  Future<void> _markAsViewed() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    await firebaseService.markTeneAsViewed(widget.tene.id);
  }

  // Delete the Tene
  Future<void> _deleteTene() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    await firebaseService.deleteTene(widget.tene.id);
    
    // Pop back to the feed screen
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // Get mood data for this Tene
  MoodData get _teneColor {
    final moodData = moodMap[widget.tene.moodId] ?? moodMap['jhappi']!;
    return moodData;
  }

  @override
  Widget build(BuildContext context) {
    final moodData = _teneColor;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              moodData.primaryColor.withAlpha(50),
              moodData.primaryColor.withAlpha(150),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: moodData.secondaryColor,
                  ),
                ),
              ),
              
              // Delete button
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: _deleteTene,
                  icon: Icon(
                    Icons.delete_outline,
                    color: moodData.secondaryColor,
                  ),
                ),
              ),
              
              // Main content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      // Sender info
                      Text(
                        widget.tene.senderName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: moodData.secondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Sent you a vibe ${timeago.format(widget.tene.timestamp)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: moodData.secondaryColor.withAlpha(200),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Mood emoji
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: moodData.primaryColor.withAlpha(70),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.tene.moodEmoji,
                            style: const TextStyle(fontSize: 70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Mood name
                      Text(
                        'Feeling ${moodMap[widget.tene.moodId]?.name ?? "Happy"}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: moodData.secondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // GIF (if provided)
                      if (widget.tene.gifUrl != null && widget.tene.gifUrl!.isNotEmpty) ...[
                        Container(
                          height: size.width * 0.7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: widget.tene.gifUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: moodData.primaryColor.withAlpha(50),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      moodData.secondaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: moodData.primaryColor.withAlpha(50),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                      
                      // Thanks button or animation
                      if (!_showThanks) ...[
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showThanks = true;
                            });
                            _controller.forward();
                            
                            // After animation completes, delete Tene
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted) {
                                _deleteTene();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: moodData.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Thank for the vibe!',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          height: 200,
                          child: Lottie.asset(
                            'assets/animations/thanks.json', 
                            controller: _controller,
                            onLoaded: (composition) {
                              _controller.duration = composition.duration;
                              _controller.forward();
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 