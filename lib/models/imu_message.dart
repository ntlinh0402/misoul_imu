import 'package:cloud_firestore/cloud_firestore.dart';

class IMUMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String message;
  final String type;
  final DateTime sentAt;
  bool isRead;
  final String? color;

  IMUMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.message,
    required this.type,
    required this.sentAt,
    required this.isRead,
    this.color,
  });

  factory IMUMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IMUMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      message: data['message'] ?? 'I miss you',
      type: data['type'] ?? 'imu',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      color: data['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'message': message,
      'type': type,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'color': color,
    };
  }
}