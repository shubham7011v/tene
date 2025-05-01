import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/screens/mood_picker_screen.dart';
import 'package:tene/screens/giphy_picker_screen.dart';
import 'package:tene/screens/contact_picker_screen.dart';

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

class _MyHomePageState extends ConsumerState<MyHomePage> {
  // Add this method to handle showing contact info
  void _showContact(String phoneNumber, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected contact: $phoneNumber'),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access current mood data
    final currentMoodId = ref.watch(currentMoodProvider);
    final moodData = ref.watch(currentMoodDataProvider);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Display current mood emoji
                Text(
                  moodData.emoji,
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),
                
                // Mood name display
                Text(
                  'Current Mood: ${moodData.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                
                // Button to navigate to mood picker
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MoodPickerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mood),
                  label: const Text('Change Mood'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Button to navigate to GIF picker
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GiphyPickerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gif),
                  label: const Text('Find a GIF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    side: BorderSide(color: moodData.secondaryColor),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Button to navigate to Contacts picker
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (context) => const ContactPickerScreen(),
                      ),
                    );
                    
                    if (result != null) {
                      _showContact(result, moodData.secondaryColor);
                    }
                  },
                  icon: const Icon(Icons.contacts),
                  label: const Text('Select a Contact'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    side: BorderSide(color: moodData.secondaryColor),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Mood selector
                Wrap(
                  spacing: 15,
                  children: moodMap.entries.map((entry) {
                    final isSelected = entry.key == currentMoodId;
                    return GestureDetector(
                      onTap: () {
                        ref.read(currentMoodProvider.notifier).state = entry.key;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? entry.value.secondaryColor 
                            : entry.value.primaryColor.withAlpha(128),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected 
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              entry.value.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            Text(entry.value.name),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
