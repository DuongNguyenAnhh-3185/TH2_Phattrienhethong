import 'dart:developer' as developer;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/supabase_client.dart';
import '../models/cloud_document_model.dart';
import '../models/document_location_model.dart';

/// Dịch vụ Quản lý Lưu trữ Tệp tin (Supabase Storage) & Cơ sở dữ liệu (Supabase Database)
class DocumentStorageService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;

  DocumentStorageService({
    SupabaseClient? supabase,
    FirebaseAuth? auth,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _auth = auth ?? FirebaseAuth.instance;

  /// Đảm bảo Custom Header `x-firebase-uid` luôn được đính kèm trước mọi truy vấn
  void _ensureCustomHeader() {
    final user = _auth.currentUser;
    if (user != null) {
      SupabaseConfig.setFirebaseUidHeader(user.uid);
    }
  }

  // ==================== 1. TẢI TỆP LÊN (UPLOAD) ====================

  /// Mở trình chọn tệp từ thiết bị và tải lên Supabase Storage + lưu vào bảng `documents`
  /// Đường dẫn lưu: `documents/${currentUser.uid}/${timestamp}_${fileName}`
  Future<CloudDocumentModel?> pickAndUploadDocument({
    Function(double progress)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập bằng tài khoản Google để thực hiện thao tác này.');
    }

    _ensureCustomHeader();

    try {
      developer.log('Khởi chạy FilePicker để chọn tệp...', name: 'DocumentStorageService');

      // 1. Mở FilePicker hỗ trợ đa định dạng (PDF, DOCX, XLSX, Ảnh,...)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'txt', 'csv', 'jpg', 'jpeg', 'png', 'webp', 'gif', 'zip', 'rar'
        ],
        allowMultiple: false,
        withData: true, // Nạp bytes vào bộ nhớ để hỗ trợ Web, Mobile, Desktop
      );

      if (result == null || result.files.isEmpty) {
        developer.log('Người dùng đã hủy chọn tệp', name: 'DocumentStorageService');
        return null;
      }

      final PlatformFile pickedFile = result.files.first;
      final int fileSize = pickedFile.size;
      final String rawFileName = pickedFile.name;

      // 2. Kiểm tra dung lượng tệp tin (tối đa 25MB)
      if (fileSize > AppConstants.maxUploadSizeBytes) {
        final double mb = fileSize / (1024 * 1024);
        throw Exception(
          'Dung lượng tệp (${mb.toStringAsFixed(1)} MB) vượt quá giới hạn tối đa cho phép (25 MB).',
        );
      }

      // Đọc dữ liệu nhị phân (bytes) của tệp
      Uint8List? fileBytes = pickedFile.bytes;
      if (fileBytes == null && pickedFile.path != null && !kIsWeb) {
        final diskFile = File(pickedFile.path!);
        if (await diskFile.exists()) {
          fileBytes = await diskFile.readAsBytes();
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('Không thể đọc dữ liệu byte của tệp tin đã chọn.');
      }

      // 3. Chuẩn hóa tên tệp và tạo đường dẫn theo đúng yêu cầu:
      // documents/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}_${fileName}
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String sanitizedFileName =
          rawFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final String storagePath =
          'documents/${user.uid}/${timestamp}_$sanitizedFileName';

      final String mimeType = _determineMimeType(sanitizedFileName);
      final String fileExt = _extractFileExtension(rawFileName);

      developer.log(
        'Bắt đầu tải tệp lên Supabase Storage: $storagePath ($fileSize bytes, MIME: $mimeType)',
        name: 'DocumentStorageService',
      );

      if (onProgress != null) onProgress(0.2);

      // 4. Tải tệp lên Supabase Storage vào bucket `documents`
      await _supabase.storage.from(AppConstants.storageBucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      if (onProgress != null) onProgress(0.7);

      developer.log('Tải lên Supabase Storage thành công!', name: 'DocumentStorageService');

      // 5. Lấy Public URL hoặc Signed URL của tệp vừa tải lên
      String fileUrl = _supabase.storage
          .from(AppConstants.storageBucket)
          .getPublicUrl(storagePath);

      try {
        // Thử sinh Signed URL (hạn 1 năm) trong trường hợp bucket được đặt là Private
        final signedUrl = await _supabase.storage
            .from(AppConstants.storageBucket)
            .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
        if (signedUrl.isNotEmpty) {
          fileUrl = signedUrl;
        }
      } catch (e) {
        developer.log('Sử dụng Public URL tiêu chuẩn: $e', name: 'DocumentStorageService');
      }

      if (onProgress != null) onProgress(0.9);

      // 6. Lưu bản ghi vào bảng `documents` trên Supabase Database
      // Các trường: id, owner_id, title, file_url, file_type, file_size, created_at, updated_at
      final DateTime now = DateTime.now();
      final Map<String, dynamic> insertPayload = {
        'owner_id': user.uid,
        'title': rawFileName,
        'file_url': fileUrl,
        'file_type': fileExt,
        'file_size': fileSize,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('documents')
          .insert(insertPayload)
          .select()
          .single();

      if (onProgress != null) onProgress(1.0);

      developer.log(
        'Đã lưu bản ghi vào bảng documents với ID: ${response['id']}',
        name: 'DocumentStorageService',
      );

      return CloudDocumentModel.fromMap(
        response,
        userRole: 'owner',
        currentUserId: user.uid,
      ).copyWith(storagePath: storagePath);
    } catch (e, stackTrace) {
      developer.log(
        'Lỗi trong quá trình upload tệp tin: $e',
        name: 'DocumentStorageService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Lỗi khi tải tệp lên: $e');
    }
  }

  // ==================== 2. TÌM KIẾM & LẤY DANH SÁCH ====================

  /// Lấy danh sách "Tài liệu của tôi" (Do chính tài khoản hiện tại làm Owner)
  /// Hỗ trợ tìm kiếm theo tiêu đề thời gian thực bằng `title.ilike.%query%`
  Future<List<CloudDocumentModel>> getMyDocuments({String? searchQuery}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    _ensureCustomHeader();

    try {
      var query = _supabase
          .from('documents')
          .select()
          .eq('owner_id', user.uid);

      // Tìm kiếm case-insensitive bằng ilike
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('title', '%${searchQuery.trim()}%');
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> list = response as List<dynamic>;

      return list
          .map((item) => CloudDocumentModel.fromMap(
                item as Map<String, dynamic>,
                userRole: 'owner',
                currentUserId: user.uid,
              ))
          .toList();
    } catch (e) {
      developer.log('Lỗi khi nạp danh sách tài liệu của tôi: $e',
          name: 'DocumentStorageService');
      throw Exception('Không thể tải danh sách tài liệu cá nhân: $e');
    }
  }

  /// Lấy danh sách "Được chia sẻ với tôi" (Dựa vào bảng `document_permissions`)
  /// Hỗ trợ tìm kiếm theo tiêu đề
  Future<List<CloudDocumentModel>> getSharedDocuments({String? searchQuery}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    _ensureCustomHeader();

    try {
      // 1. Lấy danh sách quyền từ bảng document_permissions kèm join bảng documents
      try {
        final response = await _supabase
            .from('document_permissions')
            .select('role, documents(*)')
            .eq('user_id', user.uid);

        final List<dynamic> data = response as List<dynamic>;
        final List<CloudDocumentModel> results = [];

        for (final item in data) {
          final role = (item['role'] ?? 'viewer').toString();
          final docMap = item['documents'];

          if (docMap is Map<String, dynamic>) {
            final doc = CloudDocumentModel.fromMap(
              docMap,
              userRole: role,
              currentUserId: user.uid,
            );

            // Lọc từ khóa tìm kiếm nếu có
            if (searchQuery != null && searchQuery.trim().isNotEmpty) {
              final q = searchQuery.trim().toLowerCase();
              if (!doc.title.toLowerCase().contains(q)) {
                continue;
              }
            }

            results.add(doc);
          }
        }

        // Sắp xếp ngày tạo giảm dần
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return results;
      } catch (innerError) {
        developer.log(
          'Join documents qua Postgrest gặp lỗi, thử truy vấn phân tách: $innerError',
          name: 'DocumentStorageService',
        );

        // Fallback: Truy vấn 2 bước để đảm bảo tương thích mọi cấu hình Foreign Key
        final permissionsRes = await _supabase
            .from('document_permissions')
            .select('document_id, role')
            .eq('user_id', user.uid);

        final permsList = permissionsRes as List<dynamic>;
        if (permsList.isEmpty) return [];

        final Map<String, String> roleMap = {};
        for (final p in permsList) {
          final docId = p['document_id']?.toString();
          if (docId != null) {
            roleMap[docId] = (p['role'] ?? 'viewer').toString();
          }
        }

        if (roleMap.isEmpty) return [];

        var docQuery = _supabase
            .from('documents')
            .select()
            .inFilter('id', roleMap.keys.toList());

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          docQuery = docQuery.ilike('title', '%${searchQuery.trim()}%');
        }

        final docsRes = await docQuery.order('created_at', ascending: false);
        final docsList = docsRes as List<dynamic>;

        return docsList.map((d) {
          final docId = d['id']?.toString() ?? '';
          return CloudDocumentModel.fromMap(
            d as Map<String, dynamic>,
            userRole: roleMap[docId] ?? 'viewer',
            currentUserId: user.uid,
          );
        }).toList();
      }
    } catch (e) {
      developer.log('Lỗi khi nạp danh sách tài liệu chia sẻ: $e',
          name: 'DocumentStorageService');
      throw Exception('Không thể tải tài liệu được chia sẻ: $e');
    }
  }

  // ==================== 3. CẬP NHẬT TÀI LIỆU (ĐỔI TÊN) ====================

  /// Cập nhật tên tiêu đề tài liệu (`title`)
  /// Kiểm tra quyền: Chỉ cho phép `Owner` hoặc người có quyền `editor`
  Future<void> updateDocumentTitle({
    required String documentId,
    required String newTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để chỉnh sửa tài liệu.');
    }

    final trimmedTitle = newTitle.trim();
    if (trimmedTitle.isEmpty) {
      throw Exception('Tên tài liệu không được để trống.');
    }

    _ensureCustomHeader();

    try {
      // 1. Kiểm tra tài liệu tồn tại và kiểm tra chủ sở hữu
      final docRes = await _supabase
          .from('documents')
          .select('owner_id')
          .eq('id', documentId)
          .maybeSingle();

      if (docRes == null) {
        throw Exception('Tài liệu không tồn tại hoặc đã bị xóa.');
      }

      final isOwner = docRes['owner_id'] == user.uid;

      // 2. Nếu không phải Owner, kiểm tra quyền editor trong bảng `document_permissions`
      if (!isOwner) {
        final permRes = await _supabase
            .from('document_permissions')
            .select('role')
            .eq('document_id', documentId)
            .eq('user_id', user.uid)
            .maybeSingle();

        final role = permRes?['role']?.toString().toLowerCase();
        if (role != 'editor') {
          throw Exception(
            'Bạn không có quyền chỉnh sửa tài liệu này. Yêu cầu quyền Chủ sở hữu (Owner) hoặc Người chỉnh sửa (Editor).',
          );
        }
      }

      // 3. Tiến hành cập nhật tiêu đề và dấu thời gian
      await _supabase.from('documents').update({
        'title': trimmedTitle,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      developer.log('Đã cập nhật tiêu đề tài liệu ID: $documentId',
          name: 'DocumentStorageService');
    } catch (e) {
      developer.log('Lỗi khi cập nhật tiêu đề tài liệu: $e',
          name: 'DocumentStorageService');
      rethrow;
    }
  }

  // ==================== 4. PHÂN QUYỀN & CHIA SẺ TÀI LIỆU ====================

  /// Chia sẻ tài liệu với người dùng khác qua Email và phân vai trò (`viewer` / `editor`)
  /// Kiểm tra:
  /// - Không thể tự chia sẻ cho chính mình.
  /// - Email người nhận phải tồn tại trong bảng `profiles`.
  /// - Chỉ Owner mới có quyền chia sẻ.
  Future<void> shareDocument({
    required String documentId,
    required String recipientEmail,
    required String role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để thực hiện chia sẻ tài liệu.');
    }

    final normalizedEmail = recipientEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Vui lòng nhập email người nhận.');
    }

    // 1. Kiểm tra không được tự chia sẻ cho chính mình
    if (user.email != null &&
        normalizedEmail == user.email!.trim().toLowerCase()) {
      throw Exception('Bạn không thể tự chia sẻ tài liệu cho chính mình.');
    }

    _ensureCustomHeader();

    try {
      // 2. Kiểm tra xem người gọi có phải là Owner của tài liệu không
      final docRes = await _supabase
          .from('documents')
          .select('owner_id, title')
          .eq('id', documentId)
          .maybeSingle();

      if (docRes == null) {
        throw Exception('Tài liệu cần chia sẻ không tồn tại.');
      }

      if (docRes['owner_id'] != user.uid) {
        throw Exception('Chỉ Chủ sở hữu (Owner) mới có quyền phân quyền chia sẻ tài liệu này.');
      }

      // 3. Tìm kiếm ID của người nhận trong bảng `profiles` dựa vào Email
      final profileRes = await _supabase
          .from('profiles')
          .select('id, email, display_name')
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (profileRes == null) {
        throw Exception(
          'Không tìm thấy người dùng với email "$recipientEmail".\n'
          'Người nhận cần đăng nhập vào hệ thống ít nhất một lần để tạo hồ sơ.',
        );
      }

      final recipientId = profileRes['id'] as String;

      // 4. Thêm hoặc cập nhật bản ghi phân quyền trong bảng `document_permissions`
      final existingPerm = await _supabase
          .from('document_permissions')
          .select('id')
          .eq('document_id', documentId)
          .eq('user_id', recipientId)
          .maybeSingle();

      final cleanRole = role.toLowerCase().trim(); // 'viewer' hoặc 'editor'

      if (existingPerm != null) {
        await _supabase.from('document_permissions').update({
          'role': cleanRole,
        }).eq('id', existingPerm['id']);

        developer.log(
          'Đã cập nhật vai trò phân quyền thành "$cleanRole" cho user $recipientId',
          name: 'DocumentStorageService',
        );
      } else {
        await _supabase.from('document_permissions').insert({
          'document_id': documentId,
          'user_id': recipientId,
          'role': cleanRole,
          'created_at': DateTime.now().toIso8601String(),
        });

        developer.log(
          'Đã thêm phân quyền mới ("$cleanRole") cho user $recipientId trên tài liệu $documentId',
          name: 'DocumentStorageService',
        );
      }
    } catch (e) {
      developer.log('Lỗi khi chia sẻ tài liệu: $e', name: 'DocumentStorageService');
      rethrow;
    }
  }

  // ==================== 5. XÓA TÀI LIỆU ====================

  /// Xóa tài liệu khỏi Supabase Storage và Database
  /// Chỉ cho phép Owner thực hiện
  Future<void> deleteDocument(CloudDocumentModel doc) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xóa tài liệu.');
    }

    if (!doc.isOwner && doc.ownerId != user.uid) {
      throw Exception('Chỉ Chủ sở hữu (Owner) mới có quyền xóa tài liệu này.');
    }

    _ensureCustomHeader();

    try {
      developer.log('Bắt đầu xóa tài liệu ID: ${doc.id}', name: 'DocumentStorageService');

      // 1. Xóa tệp vật lý trên Supabase Storage
      String? pathToDelete = doc.storagePath;
      if (pathToDelete == null || pathToDelete.isEmpty) {
        // Trích xuất path từ file_url nếu có
        pathToDelete = _extractStoragePathFromUrl(doc.fileUrl);
      }

      if (pathToDelete != null && pathToDelete.isNotEmpty) {
        try {
          await _supabase.storage.from(AppConstants.storageBucket).remove([pathToDelete]);
          developer.log('Đã xóa tệp trên Supabase Storage: $pathToDelete',
              name: 'DocumentStorageService');
        } catch (storageError) {
          developer.log('Lỗi xóa storage: $storageError', name: 'DocumentStorageService');
        }
      }

      // 2. Xóa các phân quyền liên quan trong bảng `document_permissions`
      try {
        await _supabase
            .from('document_permissions')
            .delete()
            .eq('document_id', doc.id);
      } catch (_) {}

      // 3. Xóa bản ghi trong bảng `documents`
      await _supabase.from('documents').delete().eq('id', doc.id);

      developer.log('Đã xóa tài liệu khỏi database thành công!', name: 'DocumentStorageService');
    } catch (e) {
      developer.log('Lỗi khi xóa tài liệu: $e', name: 'DocumentStorageService');
      throw Exception('Lỗi khi xóa tài liệu: $e');
    }
  }

  // ==================== 6. QUẢN LÝ VỊ TRÍ VẬT LÝ TÀI LIỆU ====================

  /// Lấy thông tin vị trí vật lý của tài liệu từ bảng `locations`
  Future<DocumentLocationModel?> getDocumentLocation(String documentId) async {
    _ensureCustomHeader();
    try {
      final response = await _supabase
          .from('locations')
          .select()
          .eq('document_id', documentId)
          .maybeSingle();

      if (response == null) return null;
      return DocumentLocationModel.fromMap(response);
    } catch (e) {
      developer.log('Lỗi khi lấy vị trí tài liệu: $e', name: 'DocumentStorageService');
      return null;
    }
  }

  /// Lưu hoặc cập nhật vị trí vật lý của tài liệu vào bảng `locations`
  Future<DocumentLocationModel> saveDocumentLocation(
      DocumentLocationModel location) async {
    _ensureCustomHeader();
    try {
      final payload = {
        'document_id': location.documentId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address_note': location.addressNote,
      };

      final response = await _supabase
          .from('locations')
          .upsert(payload, onConflict: 'document_id')
          .select()
          .single();

      return DocumentLocationModel.fromMap(response);
    } catch (e) {
      developer.log('Lỗi khi lưu vị trí tài liệu: $e', name: 'DocumentStorageService');
      throw Exception('Lỗi khi lưu vị trí tài liệu: $e');
    }
  }

  // ==================== TIỆN ÍCH HỖ TRỢ ====================

  String _extractFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'bin';
  }

  String? _extractStoragePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf(AppConstants.storageBucket);
      if (bucketIdx != -1 && bucketIdx < segments.length - 1) {
        return segments.sublist(bucketIdx + 1).join('/');
      }
    } catch (_) {}
    return null;
  }

  String _determineMimeType(String fileName) {
    final ext = _extractFileExtension(fileName);
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'csv':
        return 'text/csv';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }
}
