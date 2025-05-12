import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Data class representing a Tene message
class TeneData {
  final String gifUrl;
  final String vibeType;
  final DateTime sentAt;
  final String senderId;
  final String receiverId;
  final String senderPhone;
  final String receiverPhone;
  final String docId;
  bool viewed; // No longer final, can be modified locally

  TeneData({
    required this.gifUrl,
    required this.vibeType,
    required this.sentAt,
    required this.senderId,
    this.receiverId = '',
    this.senderPhone = '',
    this.receiverPhone = '',
    this.viewed = false,
    this.docId = '',
  });

  factory TeneData.fromMap(Map<String, dynamic> data, {String docId = ''}) {
    return TeneData(
      gifUrl: data['gifUrl'] ?? '',
      vibeType: data['vibeType'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderPhone: data['senderPhone'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      viewed: false, // Always false initially, we track viewed status locally
      docId: docId,
    );
  }
}

/// Result class for send operations
class SendTeneResult {
  final bool success;
  final String message;
  final TeneData? tene;

  SendTeneResult({required this.success, required this.message, this.tene});

  // Factory constructor for success
  factory SendTeneResult.success(TeneData tene) {
    return SendTeneResult(success: true, message: 'Tene sent successfully!', tene: tene);
  }

  // Factory constructor for already sent
  factory SendTeneResult.alreadySent() {
    return SendTeneResult(
      success: false,
      message: 'You have already sent a Tene to this contact. Please wait for their response.',
    );
  }

  // Factory constructor for error
  factory SendTeneResult.error(String errorMessage) {
    return SendTeneResult(success: false, message: 'Failed to send Tene: $errorMessage');
  }
}

/// Service for handling Tene operations with optimized Firestore usage
class TeneService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterSecureStorage _secureStorage;

  // In-memory set of seen tene IDs to avoid showing the same Tene twice
  final Set<String> _seenTeneIds = {};

  // Reference to the collection of tenes
  late final CollectionReference _tenesCollection;

  // Reference to the collection of user document references
  late final CollectionReference _userDocRefsCollection;

  // In-memory cache of the user's Firestore document to minimize reads
  Map<String, dynamic>? _cachedUserDoc;
  bool _hasLoadedFromFirestore = false;

  /// Constructor with dependency injection for testability
  TeneService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FlutterSecureStorage? secureStorage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
             iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
           ) {
    _tenesCollection = _firestore.collection('tenes');
    _userDocRefsCollection = _firestore.collection('userDocRefs');
  }

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Get current user phone number
  String get currentUserPhone => _auth.currentUser?.phoneNumber ?? '';

  /// Normalize a phone number by removing all spaces and non-digit characters except the + sign
  String normalizePhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    // Remove all non-digit characters except the + sign
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Store document reference in Firestore for persistence
  /// This ensures we can recover document references even if local storage is cleared
  Future<void> storeDocRefInFirestore(String contactPhone, String docRef) async {
    final userUid = currentUserId;
    if (userUid.isEmpty) return;

    final normalizedPhone = normalizePhoneNumber(contactPhone);

    try {
      // Store all contacts in a single document under the user's ID
      await _userDocRefsCollection.doc(userUid).set({
        'contactRefs': {normalizedPhone: docRef},
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error storing doc ref in Firestore: $e');
    }
  }

  /// Retrieve document reference from Firestore
  /// Used when local storage is cleared but we need to recover references
  Future<String?> getDocRefFromFirestore(String contactPhone) async {
    final userUid = currentUserId;
    if (userUid.isEmpty) return null;

    final normalizedPhone = normalizePhoneNumber(contactPhone);

    try {
      // Check if we've already loaded the user doc into memory
      if (_cachedUserDoc != null && _cachedUserDoc!.containsKey('contactRefs')) {
        final contactRefs = _cachedUserDoc!['contactRefs'] as Map<String, dynamic>;
        if (contactRefs.containsKey(normalizedPhone)) {
          return contactRefs[normalizedPhone] as String;
        }
        return null;
      }

      // If not in memory, fetch from Firestore
      final doc = await _userDocRefsCollection.doc(userUid).get();
      if (doc.exists) {
        _cachedUserDoc = doc.data() as Map<String, dynamic>;
        final contactRefs = _cachedUserDoc!['contactRefs'] as Map<String, dynamic>?;
        if (contactRefs != null && contactRefs.containsKey(normalizedPhone)) {
          return contactRefs[normalizedPhone] as String;
        }
      }
    } catch (e) {
      print('Error retrieving doc ref from Firestore: $e');
    }
    return null;
  }

  /// Cache a document reference for a contact
  /// Now stores in both secure storage (for quick access) and Firestore (for persistence)
  Future<void> cacheDocRefForContact(String contactPhone, String docRef) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);

    // Store in secure storage for fast access
    await _secureStorage.write(key: 'tene_docref_${normalizedPhone.trim()}', value: docRef);

    // Also store in Firestore for persistence across installs/storage clears
    await storeDocRefInFirestore(normalizedPhone, docRef);
  }

  /// Get cached document reference for a contact
  /// Only checks secure storage, never loads Firestore for individual contacts
  Future<String?> getCachedDocRefForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);

    // Only check secure storage, never load from Firestore for individual contacts
    return await _secureStorage.read(key: 'tene_docref_${normalizedPhone.trim()}');
  }

  /// Load the user document from Firestore and cache it in memory
  Future<void> _loadUserDocumentFromFirestore() async {
    final userUid = currentUserId;
    if (userUid.isEmpty) return;

    try {
      final doc = await _userDocRefsCollection.doc(userUid).get();
      if (doc.exists) {
        _cachedUserDoc = doc.data() as Map<String, dynamic>;
      } else {
        _cachedUserDoc = {};
      }
      _hasLoadedFromFirestore = true;
    } catch (e) {
      print('Error loading user document from Firestore: $e');
    }
  }

  /// Delete cached document reference for a contact
  Future<void> deleteDocRefForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.delete(key: 'tene_docref_${normalizedPhone.trim()}');

    // Note: We don't delete from Firestore as it serves as a backup
  }

  /// Check if a tene has been seen locally
  Future<bool> hasSeen(String teneId) async {
    return await _secureStorage.read(key: 'viewed_tene_$teneId') == 'true';
  }

  /// Mark a tene as seen locally
  Future<void> markSeen(String teneId) async {
    await _secureStorage.write(key: 'viewed_tene_$teneId', value: 'true');
  }

  /// Check if we've already sent a Tene to this contact
  /// Only checks secure storage, never loads Firestore for individual contacts
  Future<bool> hasSentTeneToContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);

    // Only check secure storage, never load from Firestore for individual contacts
    return await _secureStorage.read(key: 'sent_tene_to_${normalizedPhone}') == 'true';
  }

  /// Mark that we've sent a Tene to this contact
  Future<void> markTeneSentToContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.write(key: 'sent_tene_to_${normalizedPhone}', value: 'true');

    // Also store sent status in Firestore for persistence
    final userUid = currentUserId;
    if (userUid.isNotEmpty) {
      await _userDocRefsCollection.doc(userUid).set({
        'sentStatus': {normalizedPhone: true},
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Reset the sent status for a contact (after they've sent a Tene back)
  Future<void> resetSentStatusForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.delete(key: 'sent_tene_to_$normalizedPhone');

    // Also update in Firestore
    final userUid = currentUserId;
    if (userUid.isNotEmpty) {
      await _userDocRefsCollection.doc(userUid).set({
        'sentStatus': {normalizedPhone: false},
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Send a Tene with optimized document reference approach
  /// Never loads from Firestore for individual missing contacts
  Future<SendTeneResult> sendTene({
    required String toPhone,
    required String vibeType,
    required String gifUrl,
  }) async {
    final myUid = currentUserId;
    final myPhone = normalizePhoneNumber(currentUserPhone);
    final normalizedToPhone = normalizePhoneNumber(toPhone);

    if (myUid.isEmpty || myPhone.isEmpty) {
      return SendTeneResult.error('You must be logged in to send a Tene');
    }

    // Check if we've already sent a Tene to this contact
    // Only checks secure storage, never Firestore
    final alreadySent = await hasSentTeneToContact(normalizedToPhone);
    if (alreadySent) {
      return SendTeneResult.alreadySent();
    }

    try {
      // Try to get cached document reference for this recipient
      // Only checks secure storage, never Firestore
      final cachedDocRef = await getCachedDocRefForContact(normalizedToPhone);

      // Data to set
      final teneData = {
        'gifUrl': gifUrl,
        'vibeType': vibeType,
        'senderId': myUid,
        'senderPhone': myPhone,
        'receiverPhone': normalizedToPhone,
        'sentAt': FieldValue.serverTimestamp(),
        'totalTenes': FieldValue.increment(1),
      };

      DocumentReference docRef;
      if (cachedDocRef != null) {
        // We've sent to this person before - update existing document
        docRef = _firestore.doc(cachedDocRef);
        await docRef.set(teneData, SetOptions(merge: true));
      } else {
        // First time sending - create a new document with random ID
        docRef = await _tenesCollection.add(teneData);

        // Cache the document reference for future use
        await cacheDocRefForContact(normalizedToPhone, docRef.path);
      }

      // Mark that we've sent a Tene to this contact
      await markTeneSentToContact(normalizedToPhone);

      // When we send a Tene, mark our view status as false (waiting for their response)
      if (cachedDocRef != null) {
        _seenTeneIds.remove(cachedDocRef);
      }

      // Create a TeneData object to return
      final tene = TeneData(
        gifUrl: gifUrl,
        vibeType: vibeType,
        sentAt: DateTime.now(),
        senderId: myUid,
        senderPhone: myPhone,
        receiverPhone: normalizedToPhone,
        docId: docRef.id,
      );

      return SendTeneResult.success(tene);
    } catch (e) {
      return SendTeneResult.error(e.toString());
    }
  }

  /// Get a stream of received Tenes for the current user
  Stream<List<TeneData>> getReceivedTenes() {
    final myPhone = normalizePhoneNumber(currentUserPhone);
    final myUid = currentUserId;

    if (myPhone.isEmpty || myUid.isEmpty) {
      return Stream.value([]);
    }

    // Query the tenes collection for received Tenes
    return _tenesCollection.where('receiverPhone', isEqualTo: myPhone).snapshots().asyncMap((
      snapshot,
    ) async {
      final List<TeneData> result = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderPhone = normalizePhoneNumber(data['senderPhone'] as String? ?? '');

        // Cache the document reference for this sender
        if (senderPhone.isNotEmpty) {
          cacheDocRefForContact(senderPhone, doc.reference.path);
          await resetSentStatusForContact(senderPhone);
        }

        // Create TeneData and check if it's been viewed
        final tene = TeneData.fromMap(data, docId: doc.id);
        tene.viewed = await hasSeen(doc.id);
        result.add(tene);
      }

      return result;
    });
  }

  /// Mark a Tene as viewed locally
  Future<void> markTeneViewed(String teneId) async {
    await markSeen(teneId);
  }

  /// Get a stream of all sent Tenes by the current user
  Stream<List<TeneData>> getSentTenes() {
    final myPhone = currentUserPhone;

    if (myPhone.isEmpty) {
      return Stream.value([]);
    }

    // Query Firestore for documents where this user is the sender
    return _tenesCollection
        .where('senderPhone', isEqualTo: myPhone)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return TeneData.fromMap(data, docId: doc.id);
          }).toList();
        });
  }

  /// Get a stream of only unviewed Tenes
  Stream<List<TeneData>> getUnviewedTenes() {
    return getReceivedTenes().map((tenes) => tenes.where((tene) => !tene.viewed).toList());
  }

  /// Batch update multiple document references in Firestore
  /// More efficient when initializing or restoring multiple references
  Future<void> batchUpdateDocRefs(
    Map<String, String> contactRefs,
    Map<String, bool> sentStatus,
  ) async {
    final userUid = currentUserId;
    if (userUid.isEmpty || (contactRefs.isEmpty && sentStatus.isEmpty)) return;

    try {
      final data = <String, dynamic>{'lastUpdated': FieldValue.serverTimestamp()};

      if (contactRefs.isNotEmpty) {
        data['contactRefs'] = contactRefs;
      }

      if (sentStatus.isNotEmpty) {
        data['sentStatus'] = sentStatus;
      }

      // Update everything in a single write
      await _userDocRefsCollection.doc(userUid).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error batch updating Firestore: $e');
    }
  }

  /// Initialize sent status tracking on app start
  /// Only loads from Firestore if the entire cache is empty
  Future<void> initializeSentStatusTracking() async {
    final myPhone = normalizePhoneNumber(currentUserPhone);
    final userUid = currentUserId;

    if (myPhone.isEmpty || userUid.isEmpty) return;

    try {
      // First check if secure storage is completely empty
      final allLocalValues = await _secureStorage.readAll();

      // Only use Firestore if secure storage is completely empty
      if (allLocalValues.isEmpty) {
        print('Cache is completely empty, loading from Firestore...');
        await _loadUserDocumentFromFirestore();

        // If we have data in Firestore, restore it to secure storage
        if (_cachedUserDoc != null && _cachedUserDoc!.isNotEmpty) {
          // Restore contact refs
          if (_cachedUserDoc!.containsKey('contactRefs')) {
            final contactRefs = _cachedUserDoc!['contactRefs'] as Map<String, dynamic>;
            for (final entry in contactRefs.entries) {
              final contactPhone = entry.key;
              final docRef = entry.value as String;
              await _secureStorage.write(key: 'tene_docref_${contactPhone.trim()}', value: docRef);
            }
          }

          // Restore sent status
          if (_cachedUserDoc!.containsKey('sentStatus')) {
            final sentStatus = _cachedUserDoc!['sentStatus'] as Map<String, dynamic>;
            for (final entry in sentStatus.entries) {
              final contactPhone = entry.key;
              final isSent = entry.value as bool;

              if (isSent) {
                await _secureStorage.write(key: 'sent_tene_to_$contactPhone', value: 'true');
              }
            }
          }

          // No need to query Firestore for tenes since we already have the data
          _hasLoadedFromFirestore = true;
          return;
        }
      } else {
        // We have some data in secure storage, don't load from Firestore
        _hasLoadedFromFirestore = true;
        return;
      }

      // If we get here, cache was empty and Firestore had no data
      // We'll need to rebuild from tenes collection
      final snapshot =
          await _tenesCollection
              .where('senderPhone', isEqualTo: myPhone)
              .orderBy('sentAt', descending: true)
              .get();

      // Prepare batch updates
      final contactRefsToUpdate = <String, String>{};
      final sentStatusToUpdate = <String, bool>{};

      // Process all documents and collect data for batch update
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverPhone = normalizePhoneNumber(data['receiverPhone'] as String? ?? '');

        if (receiverPhone.isNotEmpty) {
          // Store locally
          await _secureStorage.write(
            key: 'tene_docref_${receiverPhone.trim()}',
            value: doc.reference.path,
          );

          // Add to batch update
          contactRefsToUpdate[receiverPhone] = doc.reference.path;

          // Check if this contact has sent us a Tene in response
          final hasResponse = await hasResponseFromContact(receiverPhone);

          // Update sent status locally
          if (!hasResponse) {
            await _secureStorage.write(key: 'sent_tene_to_$receiverPhone', value: 'true');
            sentStatusToUpdate[receiverPhone] = true;
          } else {
            sentStatusToUpdate[receiverPhone] = false;
          }
        }
      }

      // Perform a single Firestore update for all contacts
      if (contactRefsToUpdate.isNotEmpty || sentStatusToUpdate.isNotEmpty) {
        await batchUpdateDocRefs(contactRefsToUpdate, sentStatusToUpdate);
      }

      _hasLoadedFromFirestore = true;
    } catch (e) {
      print('Error initializing sent status: $e');
    }
  }

  /// Check if a contact has sent us a Tene
  Future<bool> hasResponseFromContact(String contactPhone) async {
    final myPhone = normalizePhoneNumber(currentUserPhone);
    final normalizedContactPhone = normalizePhoneNumber(contactPhone);

    if (myPhone.isEmpty) return false;

    try {
      final snapshot =
          await _tenesCollection
              .where('senderPhone', isEqualTo: normalizedContactPhone)
              .where('receiverPhone', isEqualTo: myPhone)
              .orderBy('sentAt', descending: true)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for the TeneService
final teneServiceProvider = Provider<TeneService>((ref) {
  return TeneService();
});

/// Provider for received Tenes
final receivedTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getReceivedTenes();
});

/// Provider for sent Tenes
final sentTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getSentTenes();
});
