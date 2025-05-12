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
  }

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Get current user phone number
  String get currentUserPhone => _auth.currentUser?.phoneNumber ?? '';

  /// Normalize a phone number by removing all spaces and non-digit characters except the + sign
  String normalizePhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    return phone.replaceAll(RegExp(r'\s+'), ''); // Remove spaces
  }

  /// Cache a document reference for a contact
  Future<void> cacheDocRefForContact(String contactPhone, String docRef) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.write(key: 'tene_docref_${normalizedPhone.trim()}', value: docRef);
  }

  /// Get cached document reference for a contact
  Future<String?> getCachedDocRefForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    return await _secureStorage.read(key: 'tene_docref_${normalizedPhone.trim()}');
  }

  /// Delete cached document reference for a contact
  Future<void> deleteDocRefForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.delete(key: 'tene_docref_${normalizedPhone.trim()}');
  }

  /// Check if a tene has been seen locally
  bool hasSeen(String teneId) {
    return _seenTeneIds.contains(teneId);
  }

  /// Mark a tene as seen locally
  void markSeen(String teneId) {
    _seenTeneIds.add(teneId);
  }

  /// Check if we've already sent a Tene to this contact
  Future<bool> hasSentTeneToContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    return await _secureStorage.read(key: 'sent_tene_to_${normalizedPhone}') == 'true';
  }

  /// Mark that we've sent a Tene to this contact
  Future<void> markTeneSentToContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.write(key: 'sent_tene_to_${normalizedPhone}', value: 'true');
  }

  /// Reset the sent status for a contact (after they've sent a Tene back)
  Future<void> resetSentStatusForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.delete(key: 'sent_tene_to_$normalizedPhone');
  }

  /// Send a Tene with optimized document reference approach
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
    final alreadySent = await hasSentTeneToContact(normalizedToPhone);
    if (alreadySent) {
      return SendTeneResult.alreadySent();
    }

    try {
      // Try to get cached document reference for this recipient
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

    if (myPhone.isEmpty) {
      return Stream.value([]);
    }

    // Query Firestore for documents where this user is the receiver
    return _tenesCollection
        .where('receiverPhone', isEqualTo: myPhone)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<TeneData> result = [];

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final senderPhone = normalizePhoneNumber(data['senderPhone'] as String? ?? '');

            // Cache the document reference for this sender
            if (senderPhone.isNotEmpty) {
              cacheDocRefForContact(senderPhone, doc.reference.path);

              // When we receive a Tene, reset the sent status for this contact
              // This allows the user to send a new Tene to this contact
              await resetSentStatusForContact(senderPhone);
            }

            // Create TeneData and check if it's been viewed
            final tene = TeneData.fromMap(data, docId: doc.id);

            // Check if we've seen this tene before
            tene.viewed = hasSeen(doc.id);

            // Add to results - we show all tenes, but mark which are viewed
            result.add(tene);
          }

          return result;
        });
  }

  /// Mark a Tene as viewed locally
  void markTeneViewed(String teneId) {
    // Just mark it as seen in our local cache
    markSeen(teneId);
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

  /// Initialize sent status tracking on app start
  Future<void> initializeSentStatusTracking() async {
    // Check for any sent Tenes and mark contacts accordingly
    final myPhone = normalizePhoneNumber(currentUserPhone);

    if (myPhone.isEmpty) return;

    try {
      final snapshot =
          await _tenesCollection
              .where('senderPhone', isEqualTo: myPhone)
              .orderBy('sentAt', descending: true)
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverPhone = normalizePhoneNumber(data['receiverPhone'] as String? ?? '');

        if (receiverPhone.isNotEmpty) {
          // Check if this contact has sent us a Tene in response
          final hasResponse = await hasResponseFromContact(receiverPhone);

          // If no response, mark as sent
          if (!hasResponse) {
            await markTeneSentToContact(receiverPhone);
          }
        }
      }
    } catch (e) {
      // Silently handle errors during initialization
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
