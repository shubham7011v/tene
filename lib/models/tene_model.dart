import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a Tene message sent between users
class TeneModel {
  final String id;
  final String senderId;
  final String senderName;
  final String phoneNumber;  // Recipient phone number
  final String fromPhone;    // Sender phone number
  final String toPhone;      // Recipient phone number (new field)
  final String moodId;
  final String moodEmoji;
  final String? gifUrl;
  final DateTime timestamp;
  final bool viewed;

  TeneModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.phoneNumber,
    this.fromPhone = '',
    this.toPhone = '',
    required this.moodId,
    required this.moodEmoji,
    this.gifUrl,
    required this.timestamp,
    this.viewed = false,
  });

  /// Create a TeneModel from Firestore document
  factory TeneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle both old and new field structures
    String? extractedGifUrl;
    
    // Check if we have the new 'media' field structure
    if (data['media'] != null && data['media'] is Map) {
      final media = data['media'] as Map<String, dynamic>;
      extractedGifUrl = media['url'] as String?;
    } else {
      // Use legacy 'gifUrl' field if available
      extractedGifUrl = data['gifUrl'] as String?;
    }
    
    return TeneModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      phoneNumber: data['phoneNumber'] ?? data['to'] ?? '', // Backward compatibility
      fromPhone: data['from'] ?? '',                        // New field
      toPhone: data['to'] ?? data['phoneNumber'] ?? '',     // New field with fallback
      moodId: data['moodId'] ?? data['mood'] ?? 'jhappi',   // Handle both field names
      moodEmoji: data['moodEmoji'] ?? '😊',
      gifUrl: extractedGifUrl,
      timestamp: (data['timestamp'] is Timestamp) 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      viewed: data['viewed'] ?? false,
    );
  }

  /// Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'phoneNumber': phoneNumber,
      'from': fromPhone,
      'to': toPhone,
      'moodId': moodId,
      'mood': moodId, // Add the new field name too
      'moodEmoji': moodEmoji,
      'media': {
        'type': 'gif',
        'url': gifUrl,
      },
      'timestamp': Timestamp.fromDate(timestamp),
      'viewed': viewed,
    };
  }

  /// Create a copy with updated fields
  TeneModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? phoneNumber,
    String? fromPhone,
    String? toPhone,
    String? moodId,
    String? moodEmoji,
    String? gifUrl,
    DateTime? timestamp,
    bool? viewed,
  }) {
    return TeneModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fromPhone: fromPhone ?? this.fromPhone,
      toPhone: toPhone ?? this.toPhone,
      moodId: moodId ?? this.moodId,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      gifUrl: gifUrl ?? this.gifUrl,
      timestamp: timestamp ?? this.timestamp,
      viewed: viewed ?? this.viewed,
    );
  }
} 