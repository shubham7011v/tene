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
  final bool viewed;

  TeneData({
    required this.gifUrl,
    required this.vibeType,
    required this.sentAt,
    required this.senderId,
    this.receiverId = '',
    this.viewed = false,
  });

  factory TeneData.fromMap(Map<String, dynamic> data) {
    return TeneData(
      gifUrl: data['lastGifUrl'] ?? '',
      vibeType: data['lastVibeType'] ?? '',
      sentAt: (data['lastSentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderId: data['lastSenderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      viewed: data['viewed'] ?? false,
    );
  }
}

/// Service for handling Tene operations with optimized Firestore usage
class TeneService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterSecureStorage _secureStorage;

  // In-memory set of seen pair IDs to avoid showing the same Tene twice
  final Set<String> _seenPairIds = {};

  // Reference to the collection of pair Tenes
  late final CollectionReference _pairTenesCollection;

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
    _pairTenesCollection = _firestore.collection('pairTenes');
  }

  /// Generate a deterministic pair ID that doesn't depend on the order of inputs
  String makePairId(String a, String b) {
    final sorted = [a, b]..sort();
    return sorted.join('_');
  }

  /// Create a pair ID using user IDs instead of phone numbers
  String makePairIdFromUids(String userAId, String userBId) {
    final sorted = [userAId, userBId]..sort();
    return sorted.join('_');
  }

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Get current user phone number
  String get currentUserPhone => _auth.currentUser?.phoneNumber ?? '';

  /// Cache a user ID for a given phone number
  Future<void> cacheUidForPhone(String phone, String uid) async {
    await _secureStorage.write(key: 'phone_uid_${phone.trim()}', value: uid);
  }

  /// Get cached user ID for a given phone number
  Future<String?> getUidForPhone(String phone) async {
    return await _secureStorage.read(key: 'phone_uid_${phone.trim()}');
  }

  /// Delete cached user ID for a given phone number
  Future<void> deleteUidForPhone(String phone) async {
    await _secureStorage.delete(key: 'phone_uid_${phone.trim()}');
  }

  /// Check if a pair Tene has been seen locally
  bool hasSeen(String pairId) {
    return _seenPairIds.contains(pairId);
  }

  /// Mark a pair Tene as seen locally
  void markSeen(String pairId) {
    _seenPairIds.add(pairId);
  }

  /// Determine if an invite should be shown (24h+ since last Tene and not viewed)
  bool shouldShowInvite(DateTime lastSent, bool hasSeen) {
    return !hasSeen && DateTime.now().difference(lastSent) > const Duration(hours: 24);
  }

  /// Generate an invite link with sender info embedded
  Future<String> generateInviteLink({
    required String senderPhone,
    required String senderUid,
  }) async {
    // This would integrate with Firebase Dynamic Links
    // For now, return a placeholder
    return 'https://tene.app/invite?sender=$senderUid&phone=$senderPhone';
  }

  /// Send a Tene with optimized single-document-per-pair approach
  Future<void> sendTene({
    required String toPhone,
    required String vibeType,
    required String gifUrl,
  }) async {
    final myUid = currentUserId;
    final myPhone = currentUserPhone;

    if (myUid.isEmpty || myPhone.isEmpty) {
      throw Exception('You must be logged in to send a Tene');
    }

    try {
      // Try to get cached UID for recipient
      final receiverUid = await getUidForPhone(toPhone);

      // Generate document ID based on UIDs if available, fallback to phones
      final String pairId;
      if (receiverUid != null && receiverUid.isNotEmpty) {
        // Preferred: Use UIDs for the pair ID
        pairId = makePairIdFromUids(myUid, receiverUid);
      } else {
        // Fallback: Use phone numbers for the pair ID
        pairId = makePairId(myPhone, toPhone);
      }

      // Get document reference
      final docRef = _pairTenesCollection.doc(pairId);

      // Set (create or overwrite) the document
      await docRef.set({
        'lastGifUrl': gifUrl,
        'lastVibeType': vibeType,
        'lastSenderId': myUid,
        'lastSenderPhone': myPhone,
        'lastReceiverPhone': toPhone,
        'lastSentAt': FieldValue.serverTimestamp(),
        'viewed': false,
        // Only include receiverId if we have it cached
        if (receiverUid != null) 'receiverId': receiverUid,
        // Increment total Tenes counter
        'totalTenes': FieldValue.increment(1),
      }, SetOptions(merge: false)); // Use false to fully overwrite the document
    } catch (e) {
      throw Exception('Failed to send Tene: $e');
    }
  }

  /// Observe incoming Tenes from a specific phone number
  Stream<TeneData> observeIncomingTenes({required String otherPhone}) {
    final myUid = currentUserId;
    final myPhone = currentUserPhone;

    if (myUid.isEmpty || myPhone.isEmpty) {
      return Stream.empty();
    }

    // Try to get the other user's UID first
    return getUidForPhone(otherPhone).asStream().asyncExpand((otherUid) {
      String pairId;

      // If we have the other user's UID, use UIDs for the pair ID
      if (otherUid != null && otherUid.isNotEmpty) {
        pairId = makePairIdFromUids(myUid, otherUid);
      } else {
        // Fallback to using phone numbers
        pairId = makePairId(myPhone, otherPhone);
      }

      // Get document reference
      final docRef = _pairTenesCollection.doc(pairId);

      // Listen to document snapshots
      return docRef
          .snapshots()
          .asyncMap((snapshot) async {
            if (!snapshot.exists) {
              return TeneData(gifUrl: '', vibeType: '', sentAt: DateTime.now(), senderId: '');
            }

            final data = snapshot.data() as Map<String, dynamic>;

            // Only process if this is from the other person and not seen locally
            if (data['lastSenderId'] != myUid && !hasSeen(pairId)) {
              // Mark as seen locally
              markSeen(pairId);

              // Cache sender UID if not already cached
              if (data['lastSenderPhone'] != null && data['lastSenderId'] != null) {
                await cacheUidForPhone(data['lastSenderPhone'], data['lastSenderId']);
              }

              return TeneData.fromMap(data);
            }

            // Return empty data for Tenes we've already seen
            return TeneData(gifUrl: '', vibeType: '', sentAt: DateTime.now(), senderId: '');
          })
          .where((tene) => tene.senderId.isNotEmpty);
    });
  }

  /// Mark a Tene as viewed locally without a Firestore write
  void markTeneViewed(String pairId) {
    markSeen(pairId);
  }

  /// Get a stream of received Tenes for the current user
  Stream<List<TeneData>> getReceivedTenes() {
    final myUid = currentUserId;
    final myPhone = currentUserPhone;

    if (myUid.isEmpty || myPhone.isEmpty) {
      return Stream.value([]);
    }

    // Query Firestore for documents where this user is involved
    return _firestore
        .collection('pairTenes')
        .where(
          Filter.or(
            Filter('lastSenderPhone', isEqualTo: myPhone),
            Filter('lastReceiverPhone', isEqualTo: myPhone),
          ),
        )
        .snapshots()
        .map((snapshot) {
          final List<TeneData> result = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();

            // Only include messages where the current user is the RECEIVER
            if (data['lastSenderId'] != myUid) {
              result.add(TeneData.fromMap(data));
            }
          }

          return result;
        });
  }

  /// Get a stream of all sent Tenes by the current user
  Stream<List<TeneData>> getSentPairTenes() {
    final myUid = currentUserId;
    final myPhone = currentUserPhone;

    if (myUid.isEmpty || myPhone.isEmpty) {
      return Stream.value([]);
    }

    // Query Firestore for documents where this user is the sender
    return _firestore
        .collection('pairTenes')
        .where('lastSenderId', isEqualTo: myUid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => TeneData.fromMap(doc.data())).toList();
        });
  }
}

/// Provider for the TeneService
final teneServiceProvider = Provider<TeneService>((ref) {
  return TeneService();
});

/// Provider for received Tenes only
final receivedTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getReceivedTenes();
});

/// Provider for generating a stream of all pair Tenes
final allPairTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getReceivedTenes();
});

/// Provider for generating a stream of sent Tenes
final sentTenesProvider = StreamProvider<List<TeneData>>((ref) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.getSentPairTenes();
});

/// Provider family for observing Tenes from a specific phone
final incomingTenesProvider = StreamProvider.family<TeneData, String>((ref, phone) {
  final teneService = ref.watch(teneServiceProvider);
  return teneService.observeIncomingTenes(otherPhone: phone);
});
