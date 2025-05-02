import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tene/models/tene_model.dart';

/// Service for handling Firebase operations related to Tenes
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user ID or empty string if not logged in
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Stream of unviewed Tenes for the current user
  Stream<List<TeneModel>> getUnviewedTenes() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tenes')
        .where('recipientId', isEqualTo: currentUserId)
        .where('viewed', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeneModel.fromFirestore(doc)).toList();
    });
  }

  /// Mark a Tene as viewed
  Future<void> markTeneAsViewed(String teneId) async {
    if (teneId.isEmpty || currentUserId.isEmpty) {
      return;
    }

    await _firestore.collection('tenes').doc(teneId).update({
      'viewed': true,
    });
  }

  /// Delete a Tene
  Future<void> deleteTene(String teneId) async {
    if (teneId.isEmpty || currentUserId.isEmpty) {
      return;
    }

    await _firestore.collection('tenes').doc(teneId).delete();
  }

  /// Send a new Tene
  Future<void> sendTene({
    required String recipientId,
    required String recipientPhone,
    required String moodId,
    required String moodEmoji,
    String? senderName,
    String? gifUrl,
  }) async {
    if (currentUserId.isEmpty) {
      throw Exception('You must be logged in to send a Tene');
    }

    final tene = {
      'senderId': currentUserId,
      'senderName': senderName ?? 'Anonymous',
      'recipientId': recipientId,
      'phoneNumber': recipientPhone,
      'moodId': moodId,
      'moodEmoji': moodEmoji,
      'gifUrl': gifUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'viewed': false,
    };

    await _firestore.collection('tenes').add(tene);
  }
} 