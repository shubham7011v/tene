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

  @override
  void initState() {
    super.initState();
    _loadAllValues();
    _checkStorageState();
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

      setState(() {
        _debugInfo =
            'Storage test: ${testValue != null ? 'SUCCESS' : 'FAILED'}\n'
            'Test value: $testValue';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cleared all cached data')));
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

  String _formatKey(String key) {
    if (key.startsWith('tene_docref_')) {
      return 'DocRef for ${key.substring('tene_docref_'.length)}';
    } else if (key.startsWith('sent_tene_to_')) {
      return 'Sent to ${key.substring('sent_tene_to_'.length)}';
    } else if (key.startsWith('phone_uid_')) {
      return 'UID for ${key.substring('phone_uid_'.length)}';
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllValues,
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
              : Column(
                children: [
                  // Debug information panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Information',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_debugInfo),
                        const SizedBox(height: 8),
                        Text('Cache Entries: ${_allValues.length}'),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Cached Data (${_allValues.length} items)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        if (_allValues.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No cached data found'),
                            ),
                          )
                        else
                          ...(_allValues.entries.map((entry) {
                            final key = entry.key;
                            final value = entry.value;
                            final keyType = _getKeyType(key);
                            final formattedKey = _formatKey(key);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ExpansionTile(
                                title: Text(formattedKey),
                                subtitle: Text(keyType),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Key: $key'),
                                        const SizedBox(height: 8),
                                        Text('Value: $value'),
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
                                  ),
                                ],
                              ),
                            );
                          }).toList()),
                        if (_allValues.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton.icon(
                              onPressed: _clearAll,
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Clear All Cached Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
        _debugInfo = 'Test entry added successfully\n$_debugInfo';
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error adding test entry: $e\n$_debugInfo';
        _isLoading = false;
      });
    }
  }
}
