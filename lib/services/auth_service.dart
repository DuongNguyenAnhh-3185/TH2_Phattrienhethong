import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../core/supabase_client.dart';

/// Dịch vụ Xác thực người dùng qua Google SSO & Đồng bộ dữ liệu định danh sang Supabase
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            ) {
    // Tự động kiểm tra và gắn header x-firebase-uid nếu người dùng đã có phiên đăng nhập từ trước
    final initialUser = _firebaseAuth.currentUser;
    if (initialUser != null) {
      SupabaseConfig.setFirebaseUidHeader(initialUser.uid);
    }
  }

  /// Lắng nghe sự thay đổi trạng thái xác thực người dùng thời gian thực (Real-time Auth State)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Lấy thông tin người dùng hiện tại
  User? get currentUser => _firebaseAuth.currentUser;

  /// Kiểm tra xem người dùng đã đăng nhập hay chưa
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Đăng nhập bằng Google Single Sign-On (SSO)
  /// Tự động Upsert hồ sơ người dùng vào bảng `profiles` trên Supabase
  /// và thiết lập header `x-firebase-uid`
  Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log('Bắt đầu quy trình đăng nhập Google SSO...', name: 'AuthService');

      // 1. Kích hoạt cửa sổ đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Trường hợp người dùng bấm Hủy / Đóng hộp thoại đăng nhập
      if (googleUser == null) {
        developer.log('Người dùng đã hủy quy trình đăng nhập Google', name: 'AuthService');
        return null;
      }

      // 2. Lấy thông tin xác thực (Tokens) từ tài khoản Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Khởi tạo Firebase Credential từ idToken và accessToken của Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập vào Firebase Auth
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        developer.log(
          'Đăng nhập Google thành công! UID: ${user.uid}, Email: ${user.email}',
          name: 'AuthService',
        );

        // 5. Thiết lập Custom Header `x-firebase-uid` cho Supabase Client
        SupabaseConfig.setFirebaseUidHeader(user.uid);

        // 6. Tự động Upsert dữ liệu người dùng vào bảng `profiles` trên Supabase
        await syncUserProfileToSupabase(user);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Lỗi FirebaseAuthException: ${e.code} - ${e.message}', name: 'AuthService');
      throw _handleFirebaseAuthError(e);
    } catch (e, stackTrace) {
      developer.log(
        'Lỗi không xác định khi đăng nhập Google: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Không thể đăng nhập bằng tài khoản Google. Vui lòng kiểm tra kết nối mạng và thử lại: $e');
    }
  }

  /// Tự động Upsert hồ sơ người dùng vào bảng `profiles` trên Supabase
  /// Cấu trúc: id (user.uid), email, display_name, avatar_url, updated_at
  Future<void> syncUserProfileToSupabase(User user) async {
    try {
      developer.log(
        'Đang đồng bộ hồ sơ người dùng vào bảng profiles Supabase (UID: ${user.uid})...',
        name: 'AuthService',
      );

      // Đảm bảo header x-firebase-uid được áp dụng
      SupabaseConfig.setFirebaseUidHeader(user.uid);

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.uid,
        'email': user.email ?? '',
        'display_name': user.displayName ?? (user.email?.split('@').first ?? 'Người dùng'),
        'avatar_url': user.photoURL ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      });

      developer.log(
        'Đồng bộ hồ sơ vào Supabase profiles thành công!',
        name: 'AuthService',
      );
    } catch (e) {
      developer.log(
        'Lỗi khi Upsert vào bảng profiles: $e',
        name: 'AuthService',
      );
      // Không chặn luồng đăng nhập nếu Supabase database chưa được cấu hình bảng
    }
  }

  /// Đăng xuất khỏi Firebase và hủy phiên Google
  Future<void> signOut() async {
    try {
      developer.log('Đang thực hiện đăng xuất...', name: 'AuthService');

      // Gỡ bỏ header trên Supabase Client
      SupabaseConfig.setFirebaseUidHeader(null);

      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);

      developer.log('Đã đăng xuất thành công!', name: 'AuthService');
    } catch (e) {
      developer.log('Lỗi khi đăng xuất: $e', name: 'AuthService');
      throw Exception('Đã xảy ra lỗi khi đăng xuất: $e');
    }
  }

  /// Xử lý mã lỗi Firebase Auth sang thông báo tiếng Việt dễ hiểu
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Email này đã được liên kết với một phương thức đăng nhập khác.';
      case 'invalid-credential':
        return 'Thông tin xác thực Google không hợp lệ hoặc đã hết hạn.';
      case 'user-disabled':
        return 'Tài khoản này đã bị tạm khóa bởi quản trị viên.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra Wifi/4G của bạn.';
      case 'popup-closed-by-user':
        return 'Hộp thoại đăng nhập đã bị đóng trước khi hoàn tất.';
      default:
        return 'Đăng nhập thất bại [${e.code}]: ${e.message ?? 'Lỗi không xác định'}';
    }
  }
}
