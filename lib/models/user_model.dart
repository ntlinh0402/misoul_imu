import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String userType;
  final String? fcmToken;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.userType,
    this.fcmToken,
    this.preferences,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      username: data['username'] ?? 'Unknown',
      email: data['email'] ?? '',
      userType: data['userType'] ?? 'patient',
      fcmToken: data['fcmToken'],
      preferences: data['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'userType': userType,
      'fcmToken': fcmToken,
      'preferences': preferences ?? {},
    };
  }
}