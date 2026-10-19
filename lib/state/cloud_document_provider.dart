import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cloud_document_model.dart';
import '../services/document_storage_service.dart';

/// Provider quản lý toàn bộ trạng thái tài liệu đám mây (Cloud Documents),
/// phân quyền (Permissions), tìm kiếm thời gian thực và đồng bộ với Supabase
class CloudDocumentProvider extends ChangeNotifier {
  final DocumentStorageService _storageService;

  List<CloudDocumentModel> _myDocuments = [];
  List<CloudDocumentModel> _sharedDocuments = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  Timer? _searchDebounce;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  CloudDocumentProvider(this._storageService);

  // ==================== GETTERS ====================

  List<CloudDocumentModel> get myDocuments => _myDocuments;
  List<CloudDocumentModel> get sharedDocuments => _sharedDocuments;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;

  int get myDocumentsCount => _myDocuments.length;
  int get sharedDocumentsCount => _sharedDocuments.length;

  // ==================== CÁC PHƯƠNG THỨC NGHIỆP VỤ ====================

  /// Tải danh sách tài liệu từ Supabase (cả tài liệu cá nhân và tài liệu được chia sẻ)
  Future<void> loadDocuments({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final myDocsFuture = _storageService.getMyDocuments(searchQuery: _searchQuery);
      final sharedDocsFuture = _storageService.getSharedDocuments(searchQuery: _searchQuery);

      final results = await Future.wait([myDocsFuture, sharedDocsFuture]);

      _myDocuments = results[0];
      _sharedDocuments = results[1];
      _errorMessage = null;
    } catch (e) {
      developer.log('Lỗi khi tải danh sách tài liệu: $e', name: 'CloudDocumentProvider');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật từ khóa tìm kiếm theo thời gian thực (với debounce 350ms)
  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      loadDocuments(silent: true);
    });
    notifyListeners();
  }

  /// Xóa từ khóa tìm kiếm
  void clearSearchQuery() {
    _searchQuery = '';
    _searchDebounce?.cancel();
    loadDocuments(silent: true);
    notifyListeners();
  }

  /// Tải tệp mới lên Supabase Storage và lưu vào Database
  Future<CloudDocumentModel?> pickAndUpload() async {
    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadStatus = 'Đang chọn tệp tin...';
    _errorMessage = null;
    notifyListeners();

    try {
      final newDoc = await _storageService.pickAndUploadDocument(
        onProgress: (progress) {
          _uploadProgress = progress;
          _uploadStatus = 'Đang tải lên: ${(progress * 100).toInt()}%';
          notifyListeners();
        },
      );

      if (newDoc != null) {
        // Tự động làm mới danh sách sau khi tải lên thành công
        await loadDocuments(silent: true);
      }

      return newDoc;
    } catch (e) {
      developer.log('Lỗi trong khi tải tệp lên: $e', name: 'CloudDocumentProvider');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isUploading = false;
      _uploadProgress = 0.0;
      _uploadStatus = '';
      notifyListeners();
    }
  }

  /// Cập nhật tên tiêu đề tài liệu
  Future<void> updateDocumentTitle(CloudDocumentModel doc, String newTitle) async {
    try {
      await _storageService.updateDocumentTitle(
        documentId: doc.id,
        newTitle: newTitle,
      );

      // Cập nhật ngay trong bộ nhớ để giao diện phản hồi tức thì
      _myDocuments = _myDocuments.map((item) {
        if (item.id == doc.id) {
          return item.copyWith(title: newTitle.trim(), updatedAt: DateTime.now());
        }
        return item;
      }).toList();

      _sharedDocuments = _sharedDocuments.map((item) {
        if (item.id == doc.id) {
          return item.copyWith(title: newTitle.trim(), updatedAt: DateTime.now());
        }
        return item;
      }).toList();

      notifyListeners();

      // Đồng bộ ngầm để đảm bảo tính nhất quán
      await loadDocuments(silent: true);
    } catch (e) {
      developer.log('Lỗi khi đổi tên tài liệu: $e', name: 'CloudDocumentProvider');
      rethrow;
    }
  }

  /// Chia sẻ tài liệu cho người dùng khác qua Email
  Future<void> shareDocument({
    required CloudDocumentModel doc,
    required String recipientEmail,
    required String role,
  }) async {
    try {
      await _storageService.shareDocument(
        documentId: doc.id,
        recipientEmail: recipientEmail,
        role: role,
      );
    } catch (e) {
      developer.log('Lỗi khi chia sẻ tài liệu: $e', name: 'CloudDocumentProvider');
      rethrow;
    }
  }

  /// Xóa tài liệu khỏi hệ thống
  Future<void> deleteDocument(CloudDocumentModel doc) async {
    try {
      await _storageService.deleteDocument(doc);

      // Xóa khỏi danh sách bộ nhớ cục bộ ngay lập tức
      _myDocuments.removeWhere((item) => item.id == doc.id);
      _sharedDocuments.removeWhere((item) => item.id == doc.id);
      notifyListeners();

      // Đồng bộ lại ngầm
      await loadDocuments(silent: true);
    } catch (e) {
      developer.log('Lỗi khi xóa tài liệu: $e', name: 'CloudDocumentProvider');
      rethrow;
    }
  }

  /// Mở hoặc Tải xuống tài liệu bằng liên kết URL ngoài
  Future<void> openDocument(CloudDocumentModel doc) async {
    if (doc.fileUrl.isEmpty) {
      throw Exception('Liên kết tệp không hợp lệ hoặc không tồn tại.');
    }

    final Uri uri = Uri.parse(doc.fileUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Không thể mở liên kết tài liệu.');
      }
    } catch (e) {
      throw Exception('Lỗi khi mở tài liệu: $e');
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
