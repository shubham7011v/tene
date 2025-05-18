import 'package:cloud_firestore/cloud_firestore.dart';

/// Data class representing a Tene message
class TeneData {
  final String gifUrl;
  final String vibeType;
  final DateTime sentAt;
  final String senderPhone;
  final String receiverPhone;
  final String docId;
  bool viewed; // No longer final, can be modified locally

  TeneData({
    required this.gifUrl,
    required this.vibeType,
    required this.sentAt,
    required this.senderPhone,
    required this.receiverPhone,
    this.viewed = false,
    this.docId = '',
  });

  factory TeneData.fromMap(Map<String, dynamic> data, {String docId = ''}) {
    return TeneData(
      gifUrl: data['gifUrl'] ?? '',
      vibeType: data['vibeType'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderPhone: data['senderPhone'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      viewed: false, // Always false initially, we track viewed status locally
      docId: docId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gifUrl': gifUrl,
      'vibeType': vibeType,
      'sentAt': sentAt,
      'senderPhone': senderPhone,
      'receiverPhone': receiverPhone,
      'viewed': viewed,
    };
  }
}
