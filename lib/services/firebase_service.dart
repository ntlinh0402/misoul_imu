import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import '../models/imu_message.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Initialize Firebase service
  Future<void> initialize() async {
    print('Đang khởi tạo Firebase Service...');

    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    try{
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      if (_auth.currentUser != null && token != null) {
        await _updateFCMToken(token);
        print('Đã cập nhật FCM token cho người dùng ${_auth.currentUser!.uid}');
      } else {
        print('Chưa cập nhật FCM token: Người dùng chưa đăng nhập hoặc token trống');
      }

    } catch (e) {
      print('Lỗi khi lấy FCM token: $e');
    }

    // Save token to Firestore if user is logged in

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token đã được làm mới: $newToken');

      _updateFCMToken(newToken);
    });
    print('Firebase Service đã được khởi tạo');

  }

  // Update FCM token in Firestore
  // Cập nhật FCM token trong Firestore
  Future<void> _updateFCMToken(String token) async {
    if (_auth.currentUser == null) {
      print('Không thể cập nhật FCM token: Người dùng chưa đăng nhập');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'fcmToken': token});
      print('Đã cập nhật FCM token trong Firestore');
    } catch (e) {
      print('Lỗi khi cập nhật FCM token: $e');

      // Kiểm tra xem document đã tồn tại chưa
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();

        if (!userDoc.exists) {
          // Tạo mới document nếu chưa tồn tại
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .set({
            'username': _auth.currentUser!.displayName ?? 'Người dùng',
            'email': _auth.currentUser!.email ?? '',
            'userType': 'unknown',
            'fcmToken': token,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Đã tạo mới document người dùng với FCM token');
        }
      } catch (e2) {
        print('Lỗi khi kiểm tra/tạo document người dùng: $e2');
      }
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Send IMU message
  Future<void> sendIMUMessage({
    required String receiverId,
    required String message,
    required String type,
    String? color,
  }) async {
    if (_auth.currentUser == null) {

      print('Lỗi: Người dùng chưa đăng nhập');

      throw Exception('User not authenticated');
    }

    try {
      print('Bắt đầu gửi tin nhắn IMU từ ${_auth.currentUser!.uid} đến $receiverId');

      // Get sender info
      DocumentSnapshot senderDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (!senderDoc.exists) {
        print('Lỗi: Không tìm thấy thông tin người gửi');
        throw Exception('Không tìm thấy thông tin người gửi');
      }

      UserModel sender = UserModel.fromFirestore(senderDoc);
      print('Thông tin người gửi: ${sender.username} (${sender.id})');


      // Create new message
      IMUMessage imuMessage = IMUMessage(
        id: '', // Firestore will generate this
        senderId: _auth.currentUser!.uid,
        receiverId: receiverId,
        senderName: sender.username,
        message: message,
        type: type,
        sentAt: DateTime.now(),
        isRead: false,
        color: color,
      );

      // Save message to Firestore
      // Lưu tin nhắn vào Firestore
      print('Đang lưu tin nhắn IMU vào Firestore...');
      DocumentReference messageRef = await _firestore.collection('imuMessages').add(imuMessage.toMap());
      print('Tin nhắn IMU đã được lưu với ID: ${messageRef.id}');
      // Get receiver's FCM token
      print('Đang lấy thông tin người nhận $receiverId...');

      DocumentSnapshot receiverDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      if (!receiverDoc.exists) {
        print('Cảnh báo: Không tìm thấy thông tin người nhận');
        return;
      }
      UserModel receiver = UserModel.fromFirestore(receiverDoc);
      print('Thông tin người nhận: ${receiver.username} (${receiver.id})');

      // If receiver has a FCM token, send notification via Cloud Functions
      // Note: This requires a Cloud Function to be set up
      if (receiver.fcmToken != null && receiver.fcmToken!.isNotEmpty) {
        print('Đang gửi thông báo đến FCM token: ${receiver.fcmToken}');

        await _firestore.collection('notifications').add({
          'token': receiver.fcmToken,
          'title': 'I MISS U',
          'body': '${sender.username} đã gửi lời yêu thương tới bạn',
          'data': {
            'type': 'imu',
            'senderId': _auth.currentUser!.uid,
            'color': color ?? '#E91E63',
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Đã gửi thông báo thành công');

      }
      else {
        print('Cảnh báo: Người nhận không có FCM token');
      }
      print('Quá trình gửi tin nhắn IMU hoàn tất');

    } catch (e) {
      print('Error sending IMU message: $e');

      throw e;
    }
  }

  // Get all IMU messages sent by current user
  // Lấy tất cả tin nhắn IMU được gửi bởi người dùng hiện tại
  Stream<List<IMUMessage>> getSentIMUMessages() {
    if (_auth.currentUser == null) {
      print('Không thể lấy tin nhắn đã gửi: Người dùng chưa đăng nhập');
      return Stream.value([]);
    }

    print('Đang lấy tin nhắn IMU đã gửi cho người dùng ${_auth.currentUser!.uid}');
    return _firestore
        .collection('imuMessages')  // Sử dụng tên collection đúng
        .where('senderId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<IMUMessage> messages = snapshot.docs
          .map((doc) => IMUMessage.fromFirestore(doc))
          .toList();
      print('Đã tìm thấy ${messages.length} tin nhắn đã gửi');
      return messages;
    });
  }

// Lấy tất cả tin nhắn IMU được nhận bởi người dùng hiện tại
  Stream<List<IMUMessage>> getReceivedIMUMessages() {
    if (_auth.currentUser == null) {
      print('Không thể lấy tin nhắn đã nhận: Người dùng chưa đăng nhập');
      return Stream.value([]);
    }

    print('Đang lấy tin nhắn IMU đã nhận cho người dùng ${_auth.currentUser!.uid}');
    return _firestore
        .collection('imuMessages')  // Sử dụng tên collection đúng
        .where('receiverId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<IMUMessage> messages = snapshot.docs
          .map((doc) => IMUMessage.fromFirestore(doc))
          .toList();
      print('Đã tìm thấy ${messages.length} tin nhắn đã nhận');
      return messages;
    });
  }

  // Get all IMU messages received by current user


  // Mark IMU message as read
  Future<void> markIMUMessageAsRead(String messageId) async {
    await _firestore
        .collection('imu_messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
}