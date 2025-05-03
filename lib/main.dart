import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tene/firebase_options.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/giphy_picker_screen.dart';
import 'package:tene/screens/tene_feed_screen.dart';
import 'package:tene/screens/home_screen.dart';
import 'package:tene/services/mood_storage_service.dart';
import 'package:tene/screens/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
    // Continue without Firebase for now
  }
  
  // Run the app with ProviderScope for Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize the saved mood
    _initializeSavedMood();
  }
  
  // Initialize the saved mood from SharedPreferences
  Future<void> _initializeSavedMood() async {
    final lastSelectedMood = await MoodStorageService.getLastSelectedMood();
    
    // If we have a saved mood, set it as the current mood
    if (lastSelectedMood != null && mounted) {
      // Update on the next frame to avoid setState during build
      Future.microtask(() {
        ref.read(currentMoodProvider.notifier).state = lastSelectedMood;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(moodThemeProvider);
    
    return MaterialApp(
      title: 'Tene - Phone Auth',
      theme: theme.copyWith(
        // Add visualDensity to reduce paddings across the app
        visualDensity: VisualDensity.compact,
        // Make buttons more compact
        buttonTheme: const ButtonThemeData(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minWidth: 0,
          height: 36,
        ),
        // Make text buttons more compact
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      home: const AuthWrapper(),
      builder: (context, child) {
        // Add extra padding around the entire app
        return MediaQuery(
          // Set a smaller text scale factor to prevent text overflow
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 0.95, // Slightly reduce text scale to prevent overflow
            padding: MediaQuery.of(context).padding.copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 8, // Add extra bottom padding
            ),
          ),
          child: Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8), // Extra bottom buffer
                child: child!,
              );
            },
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> with SingleTickerProviderStateMixin {
  // Use nullable and initialize in initState
  AnimationController? _animationController;
  bool _hasNewTene = true; // Set to true for demo purposes
  
  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController?.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    // Safely dispose the animation controller
    _animationController?.dispose();
    super.dispose();
  }
  
  // Show contact info
  void _showContact(String phoneNumber, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected contact: $phoneNumber'),
        backgroundColor: backgroundColor,
      ),
    );
  }
  
    // Start the Tene sending flow
    void _startTeneFlow() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GiphyPickerScreen(),
        ),
      );
    }
  
  // View received Tenes
  void _viewReceivedTene() {
    setState(() {
      _hasNewTene = false;
    });
    
    // Navigate to the TeneFeedScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeneFeedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access current mood data
    final moodData = ref.watch(currentMoodDataProvider);
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
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
        child: SafeArea(
          child: Stack(
            children: [
              // User avatar in top-right
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: moodData.primaryColor.withAlpha(200),
                    child: const Text(
                      "U",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main content
              Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
                    // App title
                    Text(
                      "Tene",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: moodData.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Display current mood emoji
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: moodData.primaryColor.withAlpha(40),
                      ),
                      child: Text(
                        moodData.emoji,
                        style: const TextStyle(fontSize: 120),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Mood name display
                    Text(
                      'Feeling ${moodData.name}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: moodData.secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.1),
                    
                    // Large send button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: screenSize.width * 0.8,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _startTeneFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: moodData.secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 24),
                            const SizedBox(width: 12),
            Text(
                              'Send a Tene',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // View feed button
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextButton.icon(
                        onPressed: _viewReceivedTene,
                        icon: Icon(
                          Icons.inbox_rounded, 
                          color: moodData.secondaryColor
                        ),
                        label: Text(
                          'View received Tenes',
                          style: TextStyle(
                            color: moodData.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Floating orb for new Tene notifications
      floatingActionButton: _hasNewTene ? AnimatedBuilder(
        animation: _animationController ?? const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          final animValue = _animationController?.value ?? 0.0;
          return Transform.scale(
            scale: 1.0 + (animValue * 0.1),
            child: FloatingActionButton(
              onPressed: _viewReceivedTene,
              backgroundColor: Colors.white,
              foregroundColor: moodData.secondaryColor,
              elevation: 4 + (animValue * 4),
              tooltip: 'New Tene',
              child: Stack(
                children: [
                  Icon(
                    Icons.mail_outline,
                    color: moodData.secondaryColor,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ) : null,
    );
  }
}
