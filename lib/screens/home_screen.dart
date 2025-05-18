import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/providers/auth_providers.dart';
import 'package:tene/providers/contact_providers.dart';
import 'package:tene/screens/giphy_picker_screen.dart';
import 'package:tene/screens/receive_tene_screen.dart';
import 'package:tene/screens/tene_feed_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tene/models/mood_data.dart';
import 'package:tene/models/tene_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tene/services/mood_storage_service.dart';

import 'package:tene/screens/phone_link_screen.dart';
import 'package:tene/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  bool _isChangingMood = false;
  bool _isLoading = true;
  bool _assetsPreloaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController?.repeat(reverse: true);

    // Simulate loading time and then set loading to false
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Check for phone number as soon as the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPhoneNumber();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only preload assets once
    if (!_assetsPreloaded) {
      _preloadAssets();
      _assetsPreloaded = true;
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneNumber() async {
    // Check if user has a phone number
    final user = FirebaseAuth.instance.currentUser;
    final hasPhone = user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty;

    // If no phone number, redirect to phone link screen
    if (!hasPhone && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const PhoneLinkScreen()));
    }
  }

  // Preload Lottie animations and other heavy assets
  void _preloadAssets() async {
    // Store BuildContext in a local variable before any async calls
    final localContext = context;
    final currentMood = ref.read(currentMoodProvider);

    // Preload common animations
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Start the Tene sending flow
  void _startTeneFlow() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GiphyPickerScreen()));
  }

  // Cycle to the next mood
  void _cycleMood() {
    if (_isChangingMood) return;

    setState(() {
      _isChangingMood = true;
    });

    final currentMood = ref.read(currentMoodProvider);
    final nextMood = getNextMood(currentMood);

    // Change mood with a slight delay for animation
    Future.delayed(const Duration(milliseconds: 800), () {
      ref.read(currentMoodProvider.notifier).state = nextMood;
      // Save the selected mood to SharedPreferences
      MoodStorageService.saveLastSelectedMood(nextMood);
      setState(() {
        _isChangingMood = false;
      });
    });
  }

  // Cycle to the previous mood
  void _cycleMoodReverse() {
    if (_isChangingMood) return;

    setState(() {
      _isChangingMood = true;
    });

    final currentMood = ref.read(currentMoodProvider);
    final previousMood = getPreviousMood(currentMood);

    // Change mood with a slight delay for animation
    Future.delayed(const Duration(milliseconds: 800), () {
      ref.read(currentMoodProvider.notifier).state = previousMood;
      // Save the selected mood to SharedPreferences
      MoodStorageService.saveLastSelectedMood(previousMood);
      setState(() {
        _isChangingMood = false;
      });
    });
  }

  // Show mood selector directly
  void _showMoodSelector() {
    final currentMood = ref.read(currentMoodProvider);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Your Mood'),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children:
                    cyclableMoods.map((moodId) {
                      final mood = moodMap[moodId]!;

                      return GestureDetector(
                        onTap: () {
                          ref.read(currentMoodProvider.notifier).state = moodId;
                          // Save the selected mood to SharedPreferences
                          MoodStorageService.saveLastSelectedMood(moodId);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: mood.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                currentMood == moodId
                                    ? Border.all(color: mood.secondaryColor, width: 2)
                                    : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(
                                mood.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: mood.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
              ),
            ],
          ),
    );
  }

  // View all received Tenes
  void _viewAllTenes() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TeneFeedScreen()));
  }

  // View a specific Tene
  void _viewTene(tene) {
    // Convert TeneData to TeneModel if needed
    if (tene is! TeneModel) {
      final teneModel = TeneModel(
        id: "${tene.senderId}_${DateTime.now().millisecondsSinceEpoch}",
        senderId: tene.senderId,
        receiverId: FirebaseAuth.instance.currentUser?.uid ?? '',
        vibeType: tene.vibeType,
        gifUrl: tene.gifUrl,
        sentAt: tene.sentAt,
        viewed: false,
      );
      ref.read(selectedTeneProvider.notifier).state = teneModel;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => ReceiveTeneScreen(tene: teneModel)));
    } else {
      ref.read(selectedTeneProvider.notifier).state = tene;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => ReceiveTeneScreen(tene: tene)));
    }
  }

  // Show settings menu
  void _showSettingsMenu() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final moodData = ref.watch(currentMoodDataProvider);
    final tenesAsync = ref.watch(unviewedTenesProvider);
    final user = ref.watch(authStateProvider).value;
    final currentMood = ref.watch(currentMoodProvider);

    // Winter theme colors
    final lightBlue = const Color(0xFFAEC6CF);
    final snowBlue = const Color(0xFFCDE1F0);
    const deepBlue = Color(0xFF2D4A6D);

    // Loading placeholder
    if (_isLoading) {
      return Scaffold(
        backgroundColor: moodData.primaryColor.withOpacity(0.3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(deepBlue)),
              const SizedBox(height: 20),
              Text(
                'Loading Tene...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: deepBlue),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tene',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: deepBlue,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showSettingsMenu,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Hero(
                  tag: 'profileAvatar',
                  child:
                      user != null
                          ? CircleAvatar(
                            backgroundColor: deepBlue.withOpacity(0.8),
                            radius: 24,
                            child: ClipOval(
                              child: Image.network(
                                user.photoURL ?? '',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Text(
                                      user.displayName?.substring(0, 1) ?? 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                              ),
                            ),
                          )
                          : const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: moodData.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: moodData.fabTheme.backgroundColor,
          foregroundColor: moodData.fabTheme.foregroundColor,
          elevation: moodData.fabElevation,
          shape: moodData.fabTheme.shape,
          icon: Icon(moodData.fabIcon),
          label: Text('Send a ${moodData.name} Tene', style: moodData.textStyle),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const GiphyPickerScreen()));
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Animated Mood Background
              // Gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.2)],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Mood Display Area (Full screen gesture area)
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _showMoodSelector,
                        onDoubleTap: _cycleMood,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 800),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child:
                                  _isChangingMood
                                      ? const SizedBox(height: 80)
                                      : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Feeling',
                                            key: ValueKey<String>('feeling-$currentMood'),
                                            style: const TextStyle(
                                              fontSize: 60,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D4A6D),
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            moodData.name,
                                            key: ValueKey<String>('mood-$currentMood'),
                                            style: const TextStyle(
                                              fontSize: 80,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D4A6D),
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Tap to choose mood\nDouble tap to cycle',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: moodData.secondaryColor.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white,
                                                  offset: Offset(0.5, 0.5),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tene Feed Preview Section
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.05),
                        child: tenesAsync.when(
                          data: (tenes) {
                            final previewTenes = tenes.length > 3 ? tenes.sublist(0, 3) : tenes;

                            return previewTenes.isEmpty
                                ? _buildEmptyFeedPreview()
                                : _buildTenePreviewList(previewTenes);
                          },
                          loading:
                              () => Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(deepBlue),
                                ),
                              ),
                          error: (_, __) => _buildEmptyFeedPreview(),
                        ),
                      ),
                    ),

                    // Space for floating buttons
                    SizedBox(height: maxHeight * 0.05),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build empty feed preview
  Widget _buildEmptyFeedPreview() {
    final moodData = ref.watch(currentMoodDataProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 48, color: moodData.secondaryColor.withOpacity(0.7)),
          const SizedBox(height: 16),
          const Text(
            'Your vibe inbox is empty',
            style: TextStyle(color: Color(0xFF2D4A6D), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'When friends send you Tenes, they will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5A7A99), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Build Tene preview list
  Widget _buildTenePreviewList(List tenes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Vibes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D4A6D),
                  shadows: [Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ElevatedButton(
                  onPressed: _viewAllTenes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D4A6D).withOpacity(0.1),
                    foregroundColor: const Color(0xFF2D4A6D),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFF2D4A6D).withOpacity(0.2), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All Vibes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF2D4A6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: tenes.length,
            itemBuilder: (context, index) {
              final tene = tenes[index];
              return _buildTeneCard(tene);
            },
          ),
        ),
      ],
    );
  }

  // Build individual Tene card
  Widget _buildTeneCard(tene) {
    // Use vibeType instead of moodId
    final moodColor = moodMap[tene.vibeType]?.primaryColor ?? Colors.purple;

    // Get emoji from the mood map or fallback
    final emoji = moodMap[tene.vibeType]?.emoji ?? '😊';

    // Get contact name from phone number
    final contactNameAsync = ref.watch(contactNameProvider(tene.senderPhone ?? ''));

    // Use sentAt for the timestamp
    final timestamp = tene.sentAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.7),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewTene(tene),
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
                    // Show contact name from the provider
                    contactNameAsync.when(
                      data:
                          (name) => Text(
                            '$name sent you a Tene',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D4A6D),
                            ),
                          ),
                      loading:
                          () => Text(
                            'Someone sent you a Tene',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D4A6D),
                            ),
                          ),
                      error:
                          (_, __) => Text(
                            'Someone sent you a Tene',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D4A6D),
                            ),
                          ),
                    ),
                    Text(
                      timeago.format(timestamp),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF6A8CAF), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
