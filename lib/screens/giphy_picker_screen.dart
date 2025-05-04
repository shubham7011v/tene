import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:tene/providers/providers.dart';
import 'package:tene/screens/contact_picker_screen.dart';

// State providers for the GiphyPickerScreen
final searchQueryProvider = StateProvider<String>((ref) {
  // Initialize with current mood as default search term
  final currentMood = ref.watch(currentMoodDataProvider).name;
  return currentMood;
});

final giphyResultsProvider = FutureProvider.family<List<GiphyGif>, String>((ref, query) async {
  if (query.isEmpty) return [];

  // Get API key from .env file
  final apiKey = dotenv.env['GIPHY_API_KEY'] ?? '';

  // Return empty list if API key is missing instead of throwing exception
  if (apiKey.isEmpty) {
    return [];
  }

  try {
    final url = Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=$query&limit=24&offset=0&rating=g',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['data'];

      return results
          .map(
            (gif) => GiphyGif(
              id: gif['id'],
              title: gif['title'],
              previewUrl: gif['images']['fixed_height_small']['url'],
              originalUrl: gif['images']['original']['url'],
            ),
          )
          .toList();
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
});

class GiphyGif {
  final String id;
  final String title;
  final String previewUrl;
  final String originalUrl;

  GiphyGif({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.originalUrl,
  });
}

class GiphyPickerScreen extends ConsumerStatefulWidget {
  const GiphyPickerScreen({super.key});

  @override
  ConsumerState<GiphyPickerScreen> createState() => _GiphyPickerScreenState();
}

class _GiphyPickerScreenState extends ConsumerState<GiphyPickerScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(currentMoodDataProvider).name);

    // Initialize search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchQueryProvider.notifier).state = query;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final gifsAsync = ref.watch(giphyResultsProvider(query));
    final moodData = ref.watch(currentMoodDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a GIF'), backgroundColor: moodData.primaryColor),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                fillColor: moodData.primaryColor.withAlpha(26),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Search for GIFs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),

          // GIF grid
          Expanded(
            child: gifsAsync.when(
              data: (gifs) {
                if (gifs.isEmpty) {
                  return Center(
                    child: Text(
                      query.isEmpty ? 'Enter a search term' : 'No GIFs found for "$query"',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: gifs.length,
                  itemBuilder: (context, index) {
                    final gif = gifs[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => GiphyPreviewScreen(gif: gif)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: moodData.primaryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: moodData.primaryColor.withAlpha(77)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            gif.previewUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    moodData.secondaryColor,
                                  ),
                                  backgroundColor: moodData.primaryColor.withAlpha(51),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.broken_image, color: moodData.secondaryColor),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading:
                  () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(moodData.secondaryColor),
                          backgroundColor: moodData.primaryColor.withAlpha(51),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading GIFs for "$query"...',
                          style: TextStyle(
                            color: moodData.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              error:
                  (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: moodData.secondaryColor, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading GIFs: ${error.toString()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: moodData.secondaryColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(giphyResultsProvider(query));
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class GiphyPreviewScreen extends ConsumerWidget {
  final GiphyGif gif;

  const GiphyPreviewScreen({super.key, required this.gif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodData = ref.watch(currentMoodDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(gif.title.isNotEmpty ? gif.title : 'GIF Preview'),
        backgroundColor: moodData.primaryColor,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                gif.originalUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                      valueColor: AlwaysStoppedAnimation<Color>(moodData.secondaryColor),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Save the selected gif to the provider
                ref.read(selectedGifProvider.notifier).state = gif.originalUrl;

                // Navigate to ContactPickerScreen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ContactPickerScreen(gifUrl: gif.originalUrl),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: moodData.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Select This GIF', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
