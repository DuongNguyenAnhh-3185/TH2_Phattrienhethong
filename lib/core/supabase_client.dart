import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

/// Quản lý vòng đời khởi tạo và gắn Header xác thực Firebase UID cho Supabase Client
class SupabaseConfig {
  static bool _isInitialized = false;

  /// Kiểm tra Supabase Client đã được khởi tạo hay chưa
  static bool get isInitialized => _isInitialized;

  /// Khởi tạo Supabase SDK
  static Future<void> initialize() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      // Khởi tạo Supabase Flutter (nếu chưa được khởi tạo ở main)
      try {
        await Supabase.initialize(
          url: AppConstants.supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: AppConstants.supabaseAnonKey,
          headers: {
            if (currentUid != null && currentUid.isNotEmpty)
              'x-firebase-uid': currentUid,
          },
        );
      } catch (_) {
        // Supabase đã được khởi tạo ở main()
      }

      _isInitialized = true;
      if (currentUid != null && currentUid.isNotEmpty) {
        setFirebaseUidHeader(currentUid);
      }
      developer.log(
        'Supabase đã khởi tạo thành công! (x-firebase-uid: $currentUid)',
        name: 'SupabaseConfig',
      );
    } catch (e) {
      developer.log(
        'Lưu ý khi khởi tạo Supabase: $e',
        name: 'SupabaseConfig',
      );
    }
  }

  /// Trả về SupabaseClient instance
  static SupabaseClient get client {
    if (!_isInitialized) {
      // Thử lấy client nếu đã được khởi tạo bởi hệ thống
      return Supabase.instance.client;
    }
    return Supabase.instance.client;
  }

  /// Cập nhật Custom Header `x-firebase-uid` trong mọi truy vấn Supabase
  /// để khớp với hàm kiểm tra quyền RLS `current_user_id()` trên PostgreSQL
  static void setFirebaseUidHeader(String? firebaseUid) {
    try {
      final clientInstance = Supabase.instance.client;

      if (firebaseUid != null && firebaseUid.isNotEmpty) {
        clientInstance.headers['x-firebase-uid'] = firebaseUid;
        clientInstance.rest.headers['x-firebase-uid'] = firebaseUid;
        clientInstance.storage.headers['x-firebase-uid'] = firebaseUid;
        developer.log(
          'Đã gắn Custom Header x-firebase-uid: $firebaseUid',
          name: 'SupabaseConfig',
        );
      } else {
        clientInstance.headers.remove('x-firebase-uid');
        clientInstance.rest.headers.remove('x-firebase-uid');
        clientInstance.storage.headers.remove('x-firebase-uid');
        developer.log(
          'Đã gỡ bỏ Custom Header x-firebase-uid',
          name: 'SupabaseConfig',
        );
      }
    } catch (e) {
      developer.log(
        'Lỗi khi cập nhật header Supabase: $e',
        name: 'SupabaseConfig',
      );
    }
  }
}
