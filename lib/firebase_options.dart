import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình Firebase mặc định cho ứng dụng
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Chỉ sử dụng cấu hình Android
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: 'misoul-e7176',
    storageBucket: 'misoul-e7176.appspot.com',
  );
}