import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tene/services/tene_service.dart';

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
  Map<String, dynamic> _firestoreData = {};
  bool _isLoadingFirestore = true;
  List<String> _viewedTenes = [];
  List<String> _unviewedTenes = [];

  @override
  void initState() {
    super.initState();
    _loadAllValues();
    _loadFirestoreData();
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
            'Total entries: ${allValues.length}\n'
            'Firestore will only be used if cache is completely empty';
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

  // Load data stored in Firestore
  Future<void> _loadFirestoreData() async {
    setState(() {
      _isLoadingFirestore = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _firestoreData = {};
          _isLoadingFirestore = false;
        });
        return;
      }

      // Load the single document that contains all references
      final doc = await FirebaseFirestore.instance.collection('userDocRefs').doc(userId).get();

      if (doc.exists) {
        setState(() {
          _firestoreData = doc.data() as Map<String, dynamic>;
          _isLoadingFirestore = false;

          // Add timestamp info to debug info
          final timestamp = _firestoreData['lastUpdated'] as Timestamp?;
          if (timestamp != null) {
            _debugInfo += '\nLast Firestore update: ${timestamp.toDate().toString()}';
          }
        });
      } else {
        setState(() {
          _firestoreData = {};
          _isLoadingFirestore = false;
          _debugInfo += '\nNo Firestore document found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFirestore = false;
        _debugInfo = 'Error loading Firestore data: $e\n$_debugInfo';
      });
    }
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
          const SnackBar(
            content: Text('Cleared all cached data. Firestore will be used on next app start.'),
            duration: Duration(seconds: 5),
          ),
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

  // Force initialization of the TeneService to sync Firestore data to local storage
  Future<void> _forceSyncFromFirestore() async {
    // First check if cache is completely empty
    final allValues = await _secureStorage.readAll();
    if (allValues.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache is not empty. Clear all data first to force Firestore sync.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _isLoadingFirestore = true;
    });

    try {
      // Get the TeneService from the provider
      final teneService = ref.read(teneServiceProvider);

      // Call the initialization method
      await teneService.initializeSentStatusTracking();

      // Refresh the data
      await _loadAllValues();
      await _loadFirestoreData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synced data from Firestore to local storage')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingFirestore = false;
        _debugInfo = 'Error syncing from Firestore: $e\n$_debugInfo';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error syncing: $e')));
      }
    }
  }

  // Force a direct load of Firestore document - for debug purposes only
  Future<void> _forceDirectFirestoreLoad() async {
    setState(() {
      _isLoadingFirestore = true;
    });

    try {
      // First clear the cache completely
      await _secureStorage.deleteAll();

      // Get the TeneService from the provider
      final teneService = ref.read(teneServiceProvider);

      // Initialize which will now load from Firestore (because cache is empty)
      await teneService.initializeSentStatusTracking();

      // Refresh the UI
      await _loadAllValues();
      await _loadFirestoreData();

      setState(() {
        _debugInfo = 'Forced cache clear and Firestore load\n$_debugInfo';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared and Firestore document loaded'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingFirestore = false;
        _debugInfo = 'Error loading Firestore directly: $e\n$_debugInfo';
      });
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
            onPressed: () {
              _loadAllValues();
              _loadFirestoreData();
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
          _isLoading || _isLoadingFirestore
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
                              '• Firestore is ONLY used when secure storage is COMPLETELY empty\n'
                              '• Individual missing contacts never trigger Firestore reads\n'
                              '• All data is stored in a single Firestore document\n'
                              '• To test Firestore integration, clear ALL cache data first',
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
                            Text('Firestore Cache Entries: ${_getFirestoreEntryCount()}'),
                            const SizedBox(height: 16),
                            Text(
                              'Tene View Status',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Viewed Tenes: ${_viewedTenes.length}'),
                            Text('Unviewed Tenes: ${_unviewedTenes.length}'),
                            if (_viewedTenes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Viewed Tene IDs:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ..._viewedTenes.map((id) => Text('• $id')),
                            ],
                            if (_unviewedTenes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Unviewed Tene IDs:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ..._unviewedTenes.map((id) => Text('• $id')),
                            ],
                            const SizedBox(height: 16),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _forceSyncFromFirestore,
                                    icon: const Icon(Icons.sync),
                                    label: const Text('Sync If Empty'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _forceDirectFirestoreLoad,
                                    icon: const Icon(Icons.cloud_download),
                                    label: const Text('Clear & Load'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Firestore Data Section
                      if (_firestoreData.isNotEmpty) ...[
                        Text('Firestore Document', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        _buildFirestoreDataSection(),
                        const SizedBox(height: 24),
                      ],

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
                              'No local cached data found.\n'
                              'Firestore will be used on next initialization.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        )
                      else
                        ...(_allValues.entries.map((entry) {
                          final key = entry.key;
                          final value = entry.value;
                          final keyType = _getKeyType(key);
                          final formattedKey = _formatKey(key);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              title: Text(formattedKey, overflow: TextOverflow.ellipsis),
                              subtitle: Text(keyType),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
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
                                        const SizedBox(height: 8),
                                        _buildFirestoreStatusForKey(key),
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

  // Get the count of entries in Firestore
  int _getFirestoreEntryCount() {
    int count = 0;
    if (_firestoreData.containsKey('contactRefs')) {
      count += (_firestoreData['contactRefs'] as Map<String, dynamic>).length;
    }
    return count;
  }

  // Build a widget that shows if a key exists in Firestore
  Widget _buildFirestoreStatusForKey(String key) {
    if (!key.startsWith('tene_docref_')) return const SizedBox.shrink();

    final phoneNumber = key.substring('tene_docref_'.length);
    final hasFirestoreEntry =
        _firestoreData.containsKey('contactRefs') &&
        (_firestoreData['contactRefs'] as Map<String, dynamic>).containsKey(phoneNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exists in Firestore: ${hasFirestoreEntry ? 'Yes' : 'No'}',
          style: TextStyle(
            color: hasFirestoreEntry ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!hasFirestoreEntry)
          const Text(
            'Note: Firestore won\'t be queried for this individual contact',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
      ],
    );
  }

  // Build a section that displays Firestore data
  Widget _buildFirestoreDataSection() {
    final contactRefs = _firestoreData['contactRefs'] as Map<String, dynamic>?;
    final sentStatus = _firestoreData['sentStatus'] as Map<String, dynamic>?;
    final lastUpdated = _firestoreData['lastUpdated'] as Timestamp?;

    if (contactRefs == null && sentStatus == null) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(16.0), child: Text('No Firestore data found')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Info Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Single Document Storage',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Only used when cache empty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (lastUpdated != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last Updated: ${lastUpdated.toDate().toString()}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 8),
                Text('Contact References: ${contactRefs?.length ?? 0}'),
                Text('Sent Status Records: ${sentStatus?.length ?? 0}'),
              ],
            ),
          ),

          // Display data in a table view for compactness
          if (contactRefs != null && contactRefs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact References:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(
                            label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text(
                              'Document Reference',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows:
                            contactRefs.entries.map((entry) {
                              return DataRow(
                                cells: [
                                  DataCell(SelectableText(entry.key)),
                                  DataCell(
                                    SelectableText(
                                      entry.value.toString(),
                                      style: const TextStyle(fontFamily: 'monospace'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Display sent status in a table view
          if (sentStatus != null && sentStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sent Status Records:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(
                            label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        rows:
                            sentStatus.entries.map((entry) {
                              final isSent = entry.value == true;
                              return DataRow(
                                cells: [
                                  DataCell(SelectableText(entry.key)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSent ? Icons.check_circle : Icons.cancel,
                                          color: isSent ? Colors.green : Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isSent ? 'Sent' : 'Not Sent',
                                          style: TextStyle(
                                            color: isSent ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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

      // Also add to Firestore using TeneService
      final teneService = ref.read(teneServiceProvider);

      // The storeDocRefInFirestore and markTeneSentToContact methods now
      // store everything in a single document with multiple fields
      await teneService.storeDocRefInFirestore(testPhone, docRef);
      await teneService.markTeneSentToContact(testPhone);

      // Refresh the data
      await _loadAllValues();
      await _loadFirestoreData();

      setState(() {
        _debugInfo = 'Test entry added (updates both local cache and Firestore)\n$_debugInfo';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test entry added to both local cache and Firestore'),
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
