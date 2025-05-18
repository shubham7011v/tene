import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DebugSettingsScreen extends ConsumerStatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  ConsumerState<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends ConsumerState<DebugSettingsScreen> {
  // Match exactly the same options as TeneService to ensure consistency
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  Map<String, String> _allValues = {};
  bool _isLoading = true;
  String _debugInfo = '';
  List<String> _viewedTenes = [];
  List<String> _unviewedTenes = [];

  @override
  void initState() {
    super.initState();
    _loadAllValues();
    _checkStorageState();
    _loadTeneViewStatus();
  }

  // Check storage state directly
  Future<void> _checkStorageState() async {
    try {
      // Try to write a test value
      await _secureStorage.write(
        key: 'debug_test_key',
        value: 'test_value_${DateTime.now().toString()}',
      );
      final testValue = await _secureStorage.read(key: 'debug_test_key');
      final allValues = await _secureStorage.readAll();

      setState(() {
        _debugInfo =
            'Storage test: ${testValue != null ? 'SUCCESS' : 'FAILED'}\n'
            'Test value: $testValue\n'
            'Total entries: ${allValues.length}';
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Storage test error: $e';
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAllValues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allValues = await _secureStorage.readAll();
      setState(() {
        _allValues = allValues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugInfo = 'Error loading values: $e\n$_debugInfo';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading values: $e')));
      }
    }
  }

  Future<void> _deleteValue(String key) async {
    try {
      await _secureStorage.delete(key: key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $key')));
      }
      _loadAllValues();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting $key: $e')));
      }
    }
  }

  Future<void> _clearAll() async {
    try {
      await _secureStorage.deleteAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cleared all cached data.'), duration: Duration(seconds: 5)),
        );
      }
      _loadAllValues();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing data: $e')));
      }
    }
  }

  // Load Tene view status from secure storage
  Future<void> _loadTeneViewStatus() async {
    final allValues = await _secureStorage.readAll();
    _viewedTenes = [];
    _unviewedTenes = [];

    for (var entry in allValues.entries) {
      if (entry.key.startsWith('viewed_tene_')) {
        if (entry.value == 'true') {
          _viewedTenes.add(entry.key.substring('viewed_tene_'.length));
        } else {
          _unviewedTenes.add(entry.key.substring('viewed_tene_'.length));
        }
      }
    }

    setState(() {});
  }

  String _getKeyType(String key) {
    if (key.startsWith('tene_docref_')) {
      return 'Document Reference';
    } else if (key.startsWith('sent_tene_to_')) {
      return 'Sent Status';
    } else if (key.startsWith('phone_uid_')) {
      return 'Phone UID';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAllValues();
              _loadTeneViewStatus();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _addTestEntry,
            tooltip: 'Add Test Entry',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Debug information panel
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caching Strategy',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• All data is stored in local secure storage\n'
                              '• Document references and sent status are cached locally\n'
                              '• No Firestore storage for metadata',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Divider(height: 24),
                            Text(
                              'Debug Information',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(_debugInfo),
                            const SizedBox(height: 8),
                            Text('Local Cache Entries: ${_allValues.length}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Local Storage Section
                      Text(
                        'Local Cached Data (${_allValues.length} items)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_allValues.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No local cached data found.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._allValues.entries.map((entry) {
                          final key = entry.key;
                          final value = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getKeyType(key),
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText('Key: $key'),
                                      const SizedBox(height: 8),
                                      SelectableText('Value: $value'),
                                      if (key.startsWith('tene_docref_')) ...[
                                        const SizedBox(height: 8),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        FutureBuilder<bool>(
                                          future: _getSentStatus(key),
                                          builder: (context, snapshot) {
                                            final sentStatus = snapshot.data ?? false;
                                            return Text(
                                              'Marked as sent: $sentStatus',
                                              style: TextStyle(
                                                color: sentStatus ? Colors.red : Colors.green,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _deleteValue(key),
                                            icon: const Icon(Icons.delete),
                                            label: const Text('Delete'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      if (_allValues.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Clear All Local Cached Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  // Helper method to get sent status for a document reference key
  Future<bool> _getSentStatus(String docRefKey) async {
    if (!docRefKey.startsWith('tene_docref_')) return false;

    final phone = docRefKey.substring('tene_docref_'.length);
    final sentKey = 'sent_tene_to_$phone';
    return _allValues[sentKey] == 'true';
  }

  // Add a test entry to help diagnose issues
  Future<void> _addTestEntry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a test document reference
      final testPhone = '+1234567890';
      final docRef = 'tenes/test_document_ref_${DateTime.now().millisecondsSinceEpoch}';

      // Add the test reference to secure storage
      await _secureStorage.write(key: 'tene_docref_$testPhone', value: docRef);

      // Mark as sent
      await _secureStorage.write(key: 'sent_tene_to_$testPhone', value: 'true');

      // Refresh the data
      await _loadAllValues();

      setState(() {
        _debugInfo = 'Test entry added to local cache\n$_debugInfo';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test entry added to local cache'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _debugInfo = 'Error adding test entry: $e\n$_debugInfo';
        _isLoading = false;
      });
    }
  }
}
