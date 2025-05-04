import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for a Tene message with Firestore integration
class TeneModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String vibeType;
  final String gifUrl;
  final DateTime sentAt;
  final bool viewed;
  final DateTime? viewedAt;

  TeneModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.vibeType,
    required this.gifUrl,
    required this.sentAt,
    required this.viewed,
    this.viewedAt,
  });

  /// Create a TeneModel from a Firestore DocumentSnapshot
  factory TeneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TeneModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      vibeType: data['vibeType'] ?? '',
      gifUrl: data['gifUrl'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewed: data['viewed'] ?? false,
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert TeneModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'vibeType': vibeType,
      'gifUrl': gifUrl,
      'sentAt': FieldValue.serverTimestamp(),
      'viewed': viewed,
      'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
    };
  }

  /// Create a copy of this TeneModel with some fields changed
  TeneModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? vibeType,
    String? gifUrl,
    DateTime? sentAt,
    bool? viewed,
    DateTime? viewedAt,
  }) {
    return TeneModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      vibeType: vibeType ?? this.vibeType,
      gifUrl: gifUrl ?? this.gifUrl,
      sentAt: sentAt ?? this.sentAt,
      viewed: viewed ?? this.viewed,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }

  /// Mark this Tene as viewed with current timestamp
  TeneModel markAsViewed() {
    return copyWith(viewed: true, viewedAt: DateTime.now());
  }

  /// Generate a unique document ID for a Tene between two users
  static String generateId(String senderUid, String receiverUid) {
    return '${senderUid}_$receiverUid';
  }

  @override
  String toString() {
    return 'TeneModel(id: $id, senderId: $senderId, receiverId: $receiverId, '
        'vibeType: $vibeType, viewed: $viewed)';
  }
}
