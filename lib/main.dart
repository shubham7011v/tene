import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/screens/mood_picker_screen.dart';
import 'package:tene/screens/giphy_picker_screen.dart';
import 'package:tene/screens/contact_picker_screen.dart';
import 'package:tene/screens/tene_feed_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp();
  //  print("Firebase initialized successfully");
  } catch (e) {
   // print("Failed to initialize Firebase: $e");
    // Continue without Firebase for now
  }
  
  // Run the app with ProviderScope for Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(moodThemeProvider);
    
    return MaterialApp(
      title: 'Tene Mood App',
      theme: theme,
      home: const MyHomePage(title: 'Tene Mood App'),
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
        builder: (context) => const MoodPickerScreen(),
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
