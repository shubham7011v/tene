import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a Tene message sent between users
class TeneModel {
  final String id;
  final String senderId;
  final String senderName;
  final String phoneNumber;
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
    required this.moodId,
    required this.moodEmoji,
    this.gifUrl,
    required this.timestamp,
    this.viewed = false,
  });

  /// Create a TeneModel from Firestore document
  factory TeneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeneModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      phoneNumber: data['phoneNumber'] ?? '',
      moodId: data['moodId'] ?? 'jhappi',
      moodEmoji: data['moodEmoji'] ?? '😊',
      gifUrl: data['gifUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      viewed: data['viewed'] ?? false,
    );
  }

  /// Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'phoneNumber': phoneNumber,
      'moodId': moodId,
      'moodEmoji': moodEmoji,
      'gifUrl': gifUrl,
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
      moodId: moodId ?? this.moodId,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      gifUrl: gifUrl ?? this.gifUrl,
      timestamp: timestamp ?? this.timestamp,
      viewed: viewed ?? this.viewed,
    );
  }
} 