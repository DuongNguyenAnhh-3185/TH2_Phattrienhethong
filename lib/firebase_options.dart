// File cấu hình Firebase Options
// Tạo tự động bởi FlutterFire CLI qua lệnh:
// flutterfire configure --project=<your-firebase-project-id>

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cung cấp cấu hình FirebaseOptions mặc định cho từng nền tảng
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Cấu hình mẫu cho Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_Web_Sample_ApiKey_Placeholder_123',
    appId: '1:123456789012:web:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'dms-cloud-management',
    authDomain: 'dms-cloud-management.firebaseapp.com',
    storageBucket: 'dms-cloud-management.appspot.com',
  );

  // Cấu hình mẫu cho Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_Android_Sample_ApiKey_Placeholder_123',
    appId: '1:123456789012:android:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'dms-cloud-management',
    storageBucket: 'dms-cloud-management.appspot.com',
  );

  // Cấu hình mẫu cho iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_iOS_Sample_ApiKey_Placeholder_123',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'dms-cloud-management',
    storageBucket: 'dms-cloud-management.appspot.com',
    iosBundleId: 'com.example.documentManager',
  );

  // Cấu hình mẫu cho macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA_macOS_Sample_ApiKey_Placeholder_123',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'dms-cloud-management',
    storageBucket: 'dms-cloud-management.appspot.com',
    iosBundleId: 'com.example.documentManager',
  );

  // Cấu hình mẫu cho Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA_Windows_Sample_ApiKey_Placeholder_123',
    appId: '1:123456789012:web:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'dms-cloud-management',
    authDomain: 'dms-cloud-management.firebaseapp.com',
    storageBucket: 'dms-cloud-management.appspot.com',
  );
}
