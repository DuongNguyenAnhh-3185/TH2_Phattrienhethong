import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/borrow_request_model.dart';
import '../models/recommended_document_model.dart';

/// Dịch vụ quản lý luồng Yêu cầu mượn tài liệu với Supabase Realtime
class BorrowService {
  final SupabaseClient _supabase;

  BorrowService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Lấy ID của người dùng hiện tại (hỗ trợ cả Supabase Auth và Firebase Auth)
  String? get currentUserId {
    return _supabase.auth.currentUser?.id ??
        FirebaseAuth.instance.currentUser?.uid;
  }

  /// Đảm bảo Custom Header x-firebase-uid được gắn
  void _ensureHeader() {
    final uid = currentUserId;
    if (uid != null && uid.isNotEmpty) {
      SupabaseConfig.setFirebaseUidHeader(uid);
    }
  }

  // ==================== 1. REALTIME STREAMS ====================

  /// Lắng nghe các yêu cầu mượn gửi tới tài liệu của Owner theo thời gian thực (Supabase Realtime Stream)
  Stream<List<BorrowRequestModel>> streamReceivedRequests(String ownerId) {
    _ensureHeader();
    return _supabase
        .from('borrow_requests')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false)
        .map((records) =>
            records.map((item) => BorrowRequestModel.fromMap(item)).toList());
  }

  /// Lắng nghe các yêu cầu do chính người dùng gửi đi
  Stream<List<BorrowRequestModel>> streamMySentRequests(String requesterId) {
    _ensureHeader();
    return _supabase
        .from('borrow_requests')
        .stream(primaryKey: ['id'])
        .eq('requester_id', requesterId)
        .order('created_at', ascending: false)
        .map((records) =>
            records.map((item) => BorrowRequestModel.fromMap(item)).toList());
  }

  // ==================== 2. THAO TÁC YÊU CẦU MƯỢN ====================

  /// Gửi yêu cầu mượn tài liệu mới với status = 'pending'
  Future<BorrowRequestModel> sendBorrowRequest({
    required String documentId,
    required String ownerId,
    required String requesterId,
  }) async {
    _ensureHeader();
    try {
      // Kiểm tra xem đã có request nào đang chờ hoặc đã duyệt chưa
      final existing = await _supabase
          .from('borrow_requests')
          .select()
          .eq('document_id', documentId)
          .eq('requester_id', requesterId)
          .maybeSingle();

      if (existing != null) {
        final existingStatus = (existing['status'] ?? '').toString();
        if (existingStatus == 'approved') {
          throw Exception('Bạn đã được cấp quyền truy cập tài liệu này rồi!');
        } else if (existingStatus == 'pending') {
          throw Exception('Yêu cầu mượn của bạn đang chờ chủ sở hữu phê duyệt.');
        } else {
          // Nếu bị rejected trước đó, cho phép cập nhật lại thành pending
          final updated = await _supabase
              .from('borrow_requests')
              .update({
                'status': 'pending',
                'created_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing['id'])
              .select()
              .single();
          return BorrowRequestModel.fromMap(updated);
        }
      }

      final payload = {
        'document_id': documentId,
        'owner_id': ownerId,
        'requester_id': requesterId,
        'status': 'pending',
      };

      final response =
          await _supabase.from('borrow_requests').insert(payload).select().single();

      developer.log(
        'Đã gửi yêu cầu mượn tài liệu thành công: ${response['id']}',
        name: 'BorrowService',
      );
      return BorrowRequestModel.fromMap(response);
    } catch (e) {
      developer.log('Lỗi khi gửi yêu cầu mượn: $e', name: 'BorrowService');
      rethrow;
    }
  }

  /// Cập nhật trạng thái yêu cầu mượn ('approved' hoặc 'rejected')
  Future<void> updateRequestStatus({
    required String requestId,
    required String newStatus,
  }) async {
    _ensureHeader();
    try {
      await _supabase
          .from('borrow_requests')
          .update({'status': newStatus})
          .eq('id', requestId);

      developer.log(
        'Đã cập nhật trạng thái yêu cầu $requestId thành: $newStatus',
        name: 'BorrowService',
      );
    } catch (e) {
      developer.log('Lỗi khi cập nhật trạng thái yêu cầu: $e',
          name: 'BorrowService');
      throw Exception('Không thể cập nhật yêu cầu: $e');
    }
  }

  // ==================== 3. KIỂM TRA QUYỀN TRUY CẬP ====================

  /// Kiểm tra trạng thái yêu cầu mượn của user với một tài liệu cụ thể
  Future<BorrowRequestModel?> checkUserBorrowRequest({
    required String documentId,
    required String userId,
  }) async {
    _ensureHeader();
    try {
      final response = await _supabase
          .from('borrow_requests')
          .select()
          .eq('document_id', documentId)
          .eq('requester_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return BorrowRequestModel.fromMap(response);
    } catch (e) {
      developer.log('Lỗi khi kiểm tra yêu cầu mượn: $e', name: 'BorrowService');
      return null;
    }
  }

  /// Logic kiểm tra quyền truy cập:
  /// True nếu user là Owner HOẶC có một request đã được 'approved'
  Future<bool> canAccessDocument({
    required String documentId,
    required String ownerId,
    required String userId,
  }) async {
    // 1. Nếu là chủ sở hữu, luôn có toàn quyền truy cập
    if (ownerId == userId) return true;

    // 2. Kiểm tra xem có yêu cầu mượn nào đã được approved không
    final request = await checkUserBorrowRequest(
      documentId: documentId,
      userId: userId,
    );

    return request?.isApproved == true;
  }

  /// Lấy thông tin bổ sung của tài liệu (tiêu đề, tên file) để hiển thị trong thẻ yêu cầu
  Future<Map<String, dynamic>?> getDocumentInfo(String documentId) async {
    _ensureHeader();
    try {
      final response = await _supabase
          .from('documents')
          .select('id, title, file_url, file_type, file_size')
          .eq('id', documentId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  // ==================== 4. GỢI Ý TÀI LIỆU (RECOMMENDATION) ====================

  /// Gọi Postgres RPC Function 'get_recommended_documents' để lấy danh sách gợi ý
  /// Nếu user mới chưa mượn tài liệu nào (hoặc danh sách trả về rỗng), tự động fallback lấy danh sách tài liệu mới nhất
  Future<List<RecommendedDocumentModel>> getRecommendedDocuments(
      String? userId) async {
    _ensureHeader();
    List<RecommendedDocumentModel> recommendations = [];

    // 1. Thử gọi RPC Function gợi ý tài liệu
    if (userId != null && userId.isNotEmpty) {
      try {
        dynamic response;
        try {
          response = await _supabase.rpc(
            'get_recommended_documents',
            params: {'p_user_id': userId},
          );
        } catch (_) {
          // Fallback tên hàm thứ 2 nếu hàm cũ đang dùng tên get_document_recommendations
          response = await _supabase.rpc(
            'get_document_recommendations',
            params: {'p_user_id': userId},
          );
        }

        if (response is List && response.isNotEmpty) {
          recommendations = response
              .map((item) => RecommendedDocumentModel.fromMap(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList();
          developer.log(
            'Đã lấy được ${recommendations.length} tài liệu gợi ý từ Supabase RPC!',
            name: 'BorrowService',
          );
        }
      } catch (e) {
        developer.log(
          'Lỗi khi gọi RPC get_recommended_documents: $e',
          name: 'BorrowService',
        );
      }
    }

    // 2. Fallback: Nếu user chưa có lịch sử mượn tài liệu (kết quả rỗng)
    // Lấy 10 tài liệu mới nhất từ bảng documents
    if (recommendations.isEmpty) {
      try {
        final List<dynamic> newestDocs = await _supabase
            .from('documents')
            .select()
            .order('created_at', ascending: false)
            .limit(10);

        recommendations = newestDocs
            .map((item) => RecommendedDocumentModel.fromMap(
                  Map<String, dynamic>.from(item as Map),
                  isFallback: true,
                ))
            .toList();
        developer.log(
          'Đã kích hoạt Fallback: Lấy được ${recommendations.length} tài liệu mới nhất!',
          name: 'BorrowService',
        );
      } catch (e) {
        developer.log('Lỗi khi fallback lấy tài liệu mới nhất: $e',
            name: 'BorrowService');
      }
    }

    return recommendations;
  }
}
