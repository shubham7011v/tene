import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/mood_picker_screen.dart';
import 'package:tene/screens/tene_feed_screen.dart';
import 'package:tene/screens/receive_tene_screen.dart';
import 'package:tene/screens/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tene/models/mood_data.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  bool _isChangingMood = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController?.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
  
  // Start the Tene sending flow
  void _startTeneFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MoodPickerScreen(),
      ),
    );
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
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(currentMoodProvider.notifier).state = nextMood;
      setState(() {
        _isChangingMood = false;
      });
    });
  }
  
  // View all received Tenes
  void _viewAllTenes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeneFeedScreen(),
      ),
    );
  }
  
  // View a specific Tene
  void _viewTene(tene) {
    ref.read(selectedTeneProvider.notifier).state = tene;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiveTeneScreen(tene: tene),
      ),
    );
  }

  // Show theme mode picker
  void _showThemeModePicker() {
    final currentThemeMode = ref.read(appThemeModeProvider);
    final moodData = ref.watch(currentMoodDataProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: currentThemeMode,
              activeColor: moodData.secondaryColor,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appThemeModeProvider.notifier).state = value;
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Show notification settings
  void _showNotificationSettings() {
    final notificationsEnabled = ref.read(notificationsEnabledProvider);
    final moodData = ref.watch(currentMoodDataProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: SwitchListTile(
          title: const Text('Enable Notifications'),
          value: notificationsEnabled,
          activeColor: moodData.secondaryColor,
          onChanged: (value) {
            ref.read(notificationsEnabledProvider.notifier).state = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: moodData.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Show settings menu
  void _showSettingsMenu() {
    final moodData = ref.watch(currentMoodDataProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsItem(
              icon: Icons.person,
              label: 'Your Profile',
              color: moodData.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              icon: Icons.palette,
              label: 'Theme Mode',
              color: moodData.primaryColor,
              onTap: () {
                Navigator.pop(context);
                _showThemeModePicker();
              },
            ),
            _buildSettingsItem(
              icon: Icons.notifications,
              label: 'Notification Settings',
              color: moodData.primaryColor,
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings();
              },
            ),
            _buildSettingsItem(
              icon: Icons.history,
              label: 'Tene History (dev)',
              color: moodData.primaryColor,
              onTap: () {
                Navigator.pop(context);
                _viewAllTenes();
              },
            ),
            _buildSettingsItem(
              icon: Icons.logout,
              label: 'Logout',
              color: Colors.red.shade400,
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Build settings menu item
  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodData = ref.watch(currentMoodDataProvider);
    final seasonalTheme = ref.watch(currentSeasonalThemeProvider);
    final moodLottiePath = ref.watch(currentMoodLottieProvider);
    final moodBackdropPath = ref.watch(currentMoodBackdropProvider);
    final tenesAsync = ref.watch(unviewedTenesProvider);
    final userProfile = ref.watch(userProfileProvider);
    final currentMood = ref.watch(currentMoodProvider);
    
    // Winter theme colors
    final lightBlue = const Color(0xFFAEC6CF);
    final snowBlue = const Color(0xFFCDE1F0);
    final deepBlue = const Color(0xFF6A8CAF);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tene',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
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
                  child: CircleAvatar(
                    backgroundColor: deepBlue.withOpacity(0.8),
                    radius: 24,
                    child: userProfile['avatarUrl'] != null
                        ? ClipOval(
                            child: Image.network(
                              userProfile['avatarUrl']!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                userProfile['initialLetter'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            userProfile['initialLetter'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          
          return Stack(
            children: [
              // Animated Mood Background
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Lottie.asset(
                  moodBackdropPath,
                  key: ValueKey<String>(currentMood),
                  fit: BoxFit.cover,
                  width: maxWidth,
                  height: maxHeight,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback gradient if Lottie animation can't be loaded
                    return Container(
                      key: ValueKey<String>('fallback-$currentMood'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            moodData.primaryColor.withOpacity(0.6),
                            moodData.secondaryColor.withOpacity(0.4),
                            Colors.white.withOpacity(0.8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    if (seasonalTheme.tagline.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: maxHeight * 0.02,
                          horizontal: maxWidth * 0.05,
                        ),
                        child: Text(
                          seasonalTheme.tagline,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                    // Mood Display Area (Full screen tap target)
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _cycleMood,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
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
                              child: _isChangingMood
                                ? const SizedBox(height: 80)
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Feeling',
                                        key: ValueKey<String>('feeling-${currentMood}'),
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
                                        key: ValueKey<String>('mood-${currentMood}'),
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
                                        'Tap to change mood',
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
                          loading: () => Center(
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
        }
      ),
      
      // Bottom-left pill button
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Stack(
        children: [
          // Bottom-left Send a Tene pill button
          Positioned(
            left: 20,
            bottom: 20,
            child: AnimatedBuilder(
              animation: _animationController ?? const AlwaysStoppedAnimation(0),
              builder: (context, child) {
                final animValue = _animationController?.value ?? 0.0;
                
                return Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: deepBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: animValue * 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _startTeneFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Send a Tene',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom-right icon-only FAB
          Positioned(
            right: 0,
            bottom: 20,
            child: AnimatedBuilder(
              animation: _animationController ?? const AlwaysStoppedAnimation(0),
              builder: (context, child) {
                final animValue = _animationController?.value ?? 0.0;
                
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: deepBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: animValue * 2,
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: _startTeneFlow,
                    backgroundColor: deepBlue,
                    elevation: 0,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Lottie.asset(
                        'assets/animations/send_icon_blue.json',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 48,
            color: moodData.secondaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your vibe inbox is empty',
            style: TextStyle(
              color: Color(0xFF2D4A6D),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When friends send you Tenes, they will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5A7A99),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _viewAllTenes,
            style: TextButton.styleFrom(
              foregroundColor: moodData.secondaryColor,
            ),
            child: const Text(
              'View All Tenes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
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
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Recent Vibes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D4A6D),
              shadows: [
                Shadow(
                  color: Colors.white,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
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
        Center(
          child: TextButton(
            onPressed: _viewAllTenes,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2D4A6D),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Build individual Tene card
  Widget _buildTeneCard(tene) {
    final moodColor = moodMap[tene.moodId]?.primaryColor ?? Colors.purple;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                child: Center(
                  child: Text(
                    tene.moodEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Tene content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tene.senderName} sent you a Tene',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4A6D),
                      ),
                    ),
                    Text(
                      timeago.format(tene.timestamp),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF6A8CAF),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 