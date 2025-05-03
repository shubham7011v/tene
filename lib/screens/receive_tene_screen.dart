import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/models/tene_model.dart';
import 'package:tene/providers/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tene/screens/giphy_picker_screen.dart';
import 'package:tene/screens/home_screen.dart';
import 'dart:async';

class ReceiveTeneScreen extends ConsumerStatefulWidget {
  final TeneModel tene;

  const ReceiveTeneScreen({super.key, required this.tene});

  @override
  ConsumerState<ReceiveTeneScreen> createState() => _ReceiveTeneScreenState();
}

class _ReceiveTeneScreenState extends ConsumerState<ReceiveTeneScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _countdownTimer;
  int _remainingSeconds = 10; // 10 second countdown
  bool _timerActive = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));

    // Mark the Tene as viewed when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsViewed();
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Start the countdown timer
  void _startCountdown() {
    // Store BuildContext in a local variable before any async calls
    final localContext = context;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Update the progress indicator
        _controller.value = 1 - (_remainingSeconds / 10);
      } else {
        _timerActive = false;
        timer.cancel();
        // Delete Tene when timer expires
        _markAsViewed(deleteAfterViewing: true);

        // Navigate back to home screen
        if (mounted && localContext.mounted) {
          Navigator.of(localContext).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false, // Remove all routes in the stack
          );
        }
      }
    });
  }

  // Pause or resume the timer
  void _toggleTimer() {
    if (_countdownTimer != null && _countdownTimer!.isActive) {
      _countdownTimer!.cancel();
      setState(() {
        _timerActive = false;
      });
    } else {
      _startCountdown();
      setState(() {
        _timerActive = true;
      });
    }
  }

  // Mark the Tene as viewed in Firestore
  Future<void> _markAsViewed({bool deleteAfterViewing = false}) async {
    final firebaseService = ref.read(firebaseServiceProvider);
    await firebaseService.markTeneAsViewed(widget.tene.id, deleteAfterViewing: deleteAfterViewing);
  }

  // Send a Tene back with the same mood
  void _sendTeneBack() {
    // Set the current mood to the one from this Tene
    ref.read(currentMoodProvider.notifier).state = widget.tene.moodId;

    // Navigate to GIF picker screen to start the send flow
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => const GiphyPickerScreen()));
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Timer pause/play button
          IconButton(
            icon: Icon(
              _timerActive ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
            onPressed: _toggleTimer,
          ),
          // Delete button
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
            onPressed: () async {
              // Store BuildContext in a local variable before any async calls
              final localContext = context;

              // Cancel the timer
              _countdownTimer?.cancel();

              // Mark as viewed with delete option
              await _markAsViewed(deleteAfterViewing: true);

              // Navigate back to home screen
              if (mounted && localContext.mounted) {
                Navigator.of(localContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient with mood color
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  moodData.primaryColor,
                  moodData.primaryColor.withAlpha(150),
                  moodData.secondaryColor.withAlpha(100),
                ],
              ),
            ),
          ),

          // GIF as fullscreen background (if provided)
          if (widget.tene.gifUrl != null && widget.tene.gifUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.7, // Semi-transparent
                child: CachedNetworkImage(
                  imageUrl: widget.tene.gifUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(moodData.secondaryColor),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) =>
                          Container(color: moodData.primaryColor.withAlpha(50)),
                ),
              ),
            ),

          // Gradient overlay for better readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular countdown
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      children: [
                        // Progress indicator
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _controller.value,
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            );
                          },
                        ),
                        // Seconds text
                        Center(
                          child: Text(
                            _remainingSeconds.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Sender info
                  Text(
                    'From ${widget.tene.senderName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // Large emoji display
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.tene.moodEmoji,
                        style: const TextStyle(
                          fontSize: 80,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mood name
                  Text(
                    'Feeling ${moodMap[widget.tene.moodId]?.name ?? "Happy"}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 50),

                  // "Tene Back" button
                  ElevatedButton.icon(
                    onPressed: _sendTeneBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: moodData.secondaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.reply),
                    label: const Text(
                      'Tene Back',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
