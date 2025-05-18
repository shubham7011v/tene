import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tene/models/tene_data.dart';

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
    // Remove all non-digit characters except the + sign
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Cache a document reference for a contact
  Future<void> cacheDocRefForContact(String contactPhone, DocumentReference docRef) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    // Only store in secure storage, no Firestore update
    await _secureStorage.write(key: 'tene_docref_${normalizedPhone.trim()}', value: docRef.path);
  }

  /// Get cached document reference for a contact
  Future<String?> getCachedDocRefForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    // Only check secure storage
    return await _secureStorage.read(key: 'tene_docref_${normalizedPhone.trim()}');
  }

  /// Delete cached document reference for a contact
  Future<void> deleteDocRefForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    // Only delete from secure storage
    await _secureStorage.delete(key: 'tene_docref_${normalizedPhone.trim()}');
  }

  /// Check if we've seen a Tene from this contact
  Future<bool> hasSeenTeneFromContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    return await _secureStorage.read(key: 'viewed_tene_from_$normalizedPhone') == 'true';
  }

  /// Mark that we've seen a Tene from this contact
  Future<void> markTeneSeenFromContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.write(key: 'viewed_tene_from_$normalizedPhone', value: 'true');
  }

  /// Reset the seen status for a contact (after they've sent a new Tene)
  Future<void> resetSeenStatusForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    await _secureStorage.delete(key: 'viewed_tene_from_$normalizedPhone');
  }

  /// Check if we've already sent a Tene to this contact
  /// Only checks secure storage, never loads Firestore for individual contacts
  Future<bool> hasSentTeneToContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);

    // Only check secure storage, never load from Firestore for individual contacts
    return await _secureStorage.read(key: 'sent_tene_to_$normalizedPhone') == 'true';
  }

  /// Mark that we've sent a Tene to this contact
  Future<void> markTeneSentToContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    // Only store in secure storage, no Firestore update
    await _secureStorage.write(key: 'sent_tene_to_$normalizedPhone', value: 'true');
  }

  /// Reset the sent status for a contact (after they've sent a Tene back)
  Future<void> resetSentStatusForContact(String contactPhone) async {
    final normalizedPhone = normalizePhoneNumber(contactPhone);
    // Only update secure storage, no Firestore update
    await _secureStorage.delete(key: 'sent_tene_to_$normalizedPhone');
  }

  /// Send a Tene with optimized document reference approach
  /// Never loads from Firestore for individual missing contacts
  Future<SendTeneResult> sendTene({
    required String toPhone,
    required String vibeType,
    required String gifUrl,
  }) async {
    final myPhone = normalizePhoneNumber(currentUserPhone);
    final normalizedToPhone = normalizePhoneNumber(toPhone);

    if (myPhone.isEmpty) {
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
        await cacheDocRefForContact(normalizedToPhone, docRef);
      }

      // Mark that we've sent a Tene to this contact
      await markTeneSentToContact(normalizedToPhone);

      // When we send a Tene, reset the view status (waiting for their response)
      await resetSeenStatusForContact(normalizedToPhone);

      // Create a TeneData object to return
      final tene = TeneData(
        gifUrl: gifUrl,
        vibeType: vibeType,
        sentAt: DateTime.now(),
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
          cacheDocRefForContact(senderPhone, doc.reference);
          await resetSentStatusForContact(senderPhone);
        }

        // Create TeneData and check if it's been viewed
        final tene = TeneData.fromMap(data, docId: doc.id);
        tene.viewed = await hasSeenTeneFromContact(senderPhone);
        result.add(tene);
      }

      return result;
    });
  }

  /// Mark a Tene as viewed locally
  Future<void> markTeneViewed(String senderPhone) async {
    final normalizedPhone = normalizePhoneNumber(senderPhone);
    await markTeneSeenFromContact(normalizedPhone);
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
    final myPhone = normalizePhoneNumber(currentUserPhone);
    final userUid = currentUserId;

    if (myPhone.isEmpty || userUid.isEmpty) return;

    try {
      // Check if we have any sent status entries
      final hasSentStatus = await _secureStorage.read(key: 'sent_tene_to_$myPhone') != null;

      // If we already have sent status data, we're done
      if (hasSentStatus) {
        return;
      }

      // For new users, we don't need to do anything
      if (userUid.isEmpty) {
        return;
      }

      // Only get Tenes where we are the sender
      final snapshot = await _tenesCollection.where('senderPhone', isEqualTo: myPhone).get();

      // Process each sent Tene
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverPhone = normalizePhoneNumber(data['receiverPhone'] as String? ?? '');

        if (receiverPhone.isNotEmpty) {
          // Store document reference
          await _secureStorage.write(
            key: 'tene_docref_${receiverPhone.trim()}',
            value: doc.reference.path,
          );

          // Check if this contact has sent us a Tene in response
          final hasResponse = await hasResponseFromContact(receiverPhone);

          // Only store sent status if there's no response
          if (!hasResponse) {
            await _secureStorage.write(key: 'sent_tene_to_$receiverPhone', value: 'true');
          }
        }
      }
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
