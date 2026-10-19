import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/document_filter.dart';
import '../models/document_type.dart';
import '../models/document_with_subject.dart';

/// Provider quản lý trạng thái tài liệu học tập & kết nối tầng giao diện với Drift DAO
/// Tương tự phong cách Provider/ChangeNotifier trong dự án Cashew
class DocumentProvider extends ChangeNotifier {
  final AppDatabase _db;

  DocumentFilter _filter = const DocumentFilter();

  DocumentProvider(this._db);

  DocumentFilter get filter => _filter;

  /// Luồng dữ liệu phản ứng (Reactive Stream) tài liệu kèm môn học theo bộ lọc
  Stream<List<DocumentWithSubject>> get documentsStream =>
      _db.documentDao.watchDocumentsWithSubject(filter: _filter);

  /// Luồng tổng số lượng tài liệu
  Stream<int> get totalCountStream => _db.documentDao.watchDocumentCount();

  /// Luồng số lượng tài liệu yêu thích
  Stream<int> get favoriteCountStream => _db.documentDao.watchFavoriteCount();

  // ===================== CRUD ACTIONS =====================

  /// Thêm mới tài liệu học tập
  Future<int> addDocument({
    required String title,
    String? description,
    required DocumentType documentType,
    required int subjectId,
    String tags = '',
    String? filePath,
    String fileFormat = 'pdf',
    int fileSize = 0,
    bool isFavorite = false,
  }) async {
    final now = DateTime.now();
    final companion = DocumentsCompanion.insert(
      title: title,
      description: Value(description),
      documentType: documentType,
      subjectId: subjectId,
      tags: Value(tags),
      filePath: Value(filePath),
      fileFormat: Value(fileFormat),
      fileSize: Value(fileSize),
      isFavorite: Value(isFavorite),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    final id = await _db.documentDao.insertDocument(companion);
    notifyListeners();
    return id;
  }

  /// Cập nhật thông tin tài liệu hiện có
  Future<bool> updateDocument({
    required int id,
    required String title,
    String? description,
    required DocumentType documentType,
    required int subjectId,
    String tags = '',
    String? filePath,
    String fileFormat = 'pdf',
    int fileSize = 0,
    bool isFavorite = false,
  }) async {
    final companion = DocumentsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      documentType: Value(documentType),
      subjectId: Value(subjectId),
      tags: Value(tags),
      filePath: Value(filePath),
      fileFormat: Value(fileFormat),
      fileSize: Value(fileSize),
      isFavorite: Value(isFavorite),
      updatedAt: Value(DateTime.now()),
    );

    final success = await _db.documentDao.updateDocument(companion);
    notifyListeners();
    return success;
  }

  /// Bật/tắt trạng thái yêu thích
  Future<bool> toggleFavorite(int id, bool currentStatus) async {
    final success = await _db.documentDao.toggleFavorite(id, currentStatus);
    notifyListeners();
    return success;
  }

  /// Xóa tài liệu khỏi hệ thống
  Future<int> deleteDocument(int id) async {
    final rowsAffected = await _db.documentDao.deleteDocument(id);
    notifyListeners();
    return rowsAffected;
  }

  /// Lấy chi tiết tài liệu theo ID
  Future<DocumentWithSubject?> getDocumentById(int id) {
    return _db.documentDao.getDocumentWithSubjectById(id);
  }

  // ===================== FILTER ACTIONS =====================

  /// Đặt từ khóa tìm kiếm
  void setSearchQuery(String? query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Lọc theo Môn học
  void setSubjectFilter(int? subjectId) {
    if (_filter.subjectId == subjectId) {
      // Nhấn lại lần nữa để hủy lọc môn học này
      _filter = _filter.copyWith(clearSubject: true);
    } else {
      _filter = _filter.copyWith(subjectId: subjectId);
    }
    notifyListeners();
  }

  /// Lọc theo Loại tài liệu
  void setDocumentTypeFilter(DocumentType? type) {
    if (_filter.documentType == type) {
      _filter = _filter.copyWith(clearType: true);
    } else {
      _filter = _filter.copyWith(documentType: type);
    }
    notifyListeners();
  }

  /// Chuyển đổi trạng thái chỉ hiển thị mục yêu thích
  void toggleFavoriteFilter() {
    _filter = _filter.copyWith(isFavoriteOnly: !_filter.isFavoriteOnly);
    notifyListeners();
  }

  /// Lọc theo thẻ tag
  void setTagFilter(String? tag) {
    if (_filter.tag == tag) {
      _filter = _filter.copyWith(clearTag: true);
    } else {
      _filter = _filter.copyWith(tag: tag);
    }
    notifyListeners();
  }

  /// Đặt tiêu chí sắp xếp
  void setSortOption(SortOption sortBy) {
    _filter = _filter.copyWith(sortBy: sortBy);
    notifyListeners();
  }

  /// Đặt lại toàn bộ bộ lọc
  void resetFilter() {
    _filter = _filter.reset();
    notifyListeners();
  }
}
