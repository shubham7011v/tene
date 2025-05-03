import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tene/models/tene_model.dart';
import 'package:tene/models/mood_data.dart';
import 'package:tene/services/service_locator.dart';

/// Service for handling Firebase operations related to Tenes
class FirebaseService {
  // Get Firebase instances from the ServiceLocator
  FirebaseAuth get _auth => ServiceLocator.instance.auth;
  FirebaseFirestore get _firestore => ServiceLocator.instance.firestore;

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

  /// Stream of unviewed Tenes for a specific phone number
  Stream<List<TeneModel>> getUnviewedTenesByPhone(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tenes')
        .where('to', isEqualTo: phoneNumber)
        .where('viewed', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeneModel.fromFirestore(doc)).toList();
    });
  }

  /// Mark a Tene as viewed
  Future<void> markTeneAsViewed(String teneId, {bool deleteAfterViewing = false}) async {
    if (teneId.isEmpty || currentUserId.isEmpty) {
      return;
    }

    if (deleteAfterViewing) {
      // Delete the Tene completely for full ephemerality
      await _firestore.collection('tenes').doc(teneId).delete();
    } else {
      // Just mark it as viewed
      await _firestore.collection('tenes').doc(teneId).update({
        'viewed': true,
      });
    }
  }

  /// Delete a Tene
  Future<void> deleteTene(String teneId) async {
    if (teneId.isEmpty || currentUserId.isEmpty) {
      return;
    }

    await _firestore.collection('tenes').doc(teneId).delete();
  }

  /// Send a new Tene with structured media data
  Future<void> sendTene({
    required String fromPhone,
    required String toPhone,
    required String mood,
    required String mediaUrl,
  }) async {
    // Ensure we have a valid sender ID
    if (currentUserId.isEmpty) {
      throw Exception('You must be logged in to send a Tene');
    }
    
    // Get the mood emoji from the mood ID
    final moodEmoji = moodMap[mood]?.emoji ?? '😊';
    
    // Create the Tene document
    final tene = {
      'from': fromPhone,
      'to': toPhone,
      'mood': mood,
      'moodEmoji': moodEmoji,
      'media': {
        'type': 'gif',
        'url': mediaUrl,
      },
      'timestamp': FieldValue.serverTimestamp(),
      'viewed': false,
      'senderId': currentUserId,
      'senderName': _auth.currentUser?.displayName ?? 'Anonymous',
    };
    
    // Add the document to the 'tenes' collection
    await _firestore.collection('tenes').add(tene);
  }
} 